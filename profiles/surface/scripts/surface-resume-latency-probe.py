#!/usr/bin/env python3
"""Surface post-resume input-latency probe (diagnostic only, no system changes).

Runs as root for ~90s after resume (started asynchronously by
/etc/systemd/system-sleep/22-surface-resume-probe.sh) and logs to the journal:

  * every 0.5s: scheduler overshoot (jitter), CPU freq/EPP, PSI cpu/io/memory,
    and for Hyprland + noctalia: state, CPU ticks and major page faults
  * every key press on the built-in Surface keyboard: kernel event timestamp vs
    the time this probe read it (lag_ms). Key CODES are never logged.

Reading the result:
  * key lag_ms ~0 but you saw typing delayed  -> keyboard/kernel is fine;
    compositor or lock screen was stalled (check hypr/noctalia faults + PSI)
  * key lag_ms large                           -> kernel/HID/SAM delay
Inspect with: journalctl -u surface-resume-probe -b --no-pager
"""
import fcntl
import glob
import os
import select
import socket
import struct
import sys
import threading
import time

DURATION = float(os.environ.get("PROBE_SECONDS", "90"))
INTERVAL = 0.5
KBD_NAME = "Microsoft Surface 045E:09AE Keyboard"
EV_FMT = "llHHi"
EV_SIZE = struct.calcsize(EV_FMT)
EV_KEY = 1
EVIOCSCLOCKID = 0x400445a0  # make evdev timestamps CLOCK_MONOTONIC (default is REALTIME)
CLK_TCK = os.sysconf("SC_CLK_TCK")


def log(msg):
    print(msg, flush=True)


def read(path, default=""):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def find_kbd():
    for p in sorted(glob.glob("/sys/class/input/event*")):
        if read(p + "/device/name") == KBD_NAME:
            return "/dev/input/" + os.path.basename(p)
    return None


def find_pid(comm):
    for d in glob.glob("/proc/[0-9]*"):
        if read(d + "/comm") == comm:
            return int(os.path.basename(d))
    return None


def proc_stat(pid):
    """Return (state, cpu_ticks, majflt) or None."""
    raw = read("/proc/%d/stat" % pid)
    if not raw:
        return None
    f = raw[raw.rfind(")") + 2:].split()
    return f[0], int(f[11]) + int(f[12]), int(f[9])


def psi(name):
    out = {}
    for line in read("/proc/pressure/" + name).splitlines():
        parts = line.split()
        kv = dict(p.split("=") for p in parts[1:])
        out[parts[0]] = (float(kv["avg10"]), int(kv["total"]))
    return out


def mean_freq_mhz():
    vals = []
    for p in glob.glob("/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq"):
        try:
            vals.append(int(read(p, "0")))
        except ValueError:
            pass
    return (sum(vals) / len(vals) / 1000) if vals else 0


def hypr_dir():
    dirs = sorted(glob.glob("/run/user/*/hypr/*/.socket.sock"))
    return os.path.dirname(dirs[-1]) if dirs else None


def hypr_ipc_watch(t0, stop, state):
    """Round-trip the Hyprland command socket every ~100ms. A stalled
    compositor main loop shows up as a long RTT. Also log Hyprland event NAMES
    (not payloads) with timestamps from socket2."""
    d = hypr_dir()
    if not d:
        log("probe: hyprland socket not found")
        return

    def events():
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(d + "/.socket2.sock")
            s.settimeout(1.0)
            buf = b""
            while not stop.is_set():
                try:
                    chunk = s.recv(4096)
                except socket.timeout:
                    continue
                if not chunk:
                    break
                buf += chunk
                while b"\n" in buf:
                    line, buf = buf.split(b"\n", 1)
                    name = line.split(b">>", 1)[0].decode(errors="replace")
                    if name not in ("mousemove",):
                        log("t+%5.2fs hypr-event %s" % (time.monotonic() - t0, name))
        except OSError as e:
            log("probe: hypr events ended: %s" % e)

    threading.Thread(target=events, daemon=True).start()

    while not stop.is_set():
        a = time.monotonic()
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.settimeout(5.0)
            s.connect(d + "/.socket.sock")
            s.sendall(b"version")
            while s.recv(4096):
                pass
            s.close()
            rtt = (time.monotonic() - a) * 1000
        except OSError:
            rtt = -1
        state["max"] = max(state.get("max", 0), rtt)
        if rtt > 40 or rtt < 0:
            log("t+%5.2fs hypr-ipc rtt_ms=%.0f" % (a - t0, rtt))
        time.sleep(0.1)


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "?"
    t0 = time.monotonic()
    kbd_path = find_kbd()
    kbd = None
    if kbd_path:
        try:
            kbd = os.open(kbd_path, os.O_RDONLY | os.O_NONBLOCK)
            fcntl.ioctl(kbd, EVIOCSCLOCKID, struct.pack("i", time.CLOCK_MONOTONIC))
        except OSError as e:
            log("probe: cannot open %s: %s" % (kbd_path, e))
    log("probe: start action=%s kbd=%s profile=%s epp=%s duration=%ss"
        % (action, kbd_path, read("/sys/firmware/acpi/platform_profile"),
           read("/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference"),
           DURATION))

    stop = threading.Event()
    ipc = {}
    threading.Thread(target=hypr_ipc_watch, args=(t0, stop, ipc), daemon=True).start()

    pids = {}
    last_stat = {}
    last_psi = psi("io"), psi("memory"), psi("cpu")
    next_tick = t0
    first_key_logged = 0

    while True:
        now = time.monotonic()
        if now - t0 > DURATION:
            break
        timeout = max(0.0, next_tick - now)
        if kbd is not None:
            r, _, _ = select.select([kbd], [], [], timeout)
            if r:
                try:
                    data = os.read(kbd, EV_SIZE * 64)
                except OSError:
                    data = b""
                    kbd = None
                    log("probe: keyboard fd lost (device re-created?)")
                rd = time.monotonic()
                for off in range(0, len(data) - EV_SIZE + 1, EV_SIZE):
                    sec, usec, typ, _code, val = struct.unpack_from(EV_FMT, data, off)
                    if typ == EV_KEY and val == 1:
                        first_key_logged += 1
                        log("key#%d t+%.2fs lag_ms=%.1f"
                            % (first_key_logged, rd - t0, (rd - (sec + usec / 1e6)) * 1000))
                continue
        else:
            time.sleep(timeout)

        tick_now = time.monotonic()
        if tick_now < next_tick:
            continue
        jitter_ms = (tick_now - next_tick) * 1000
        next_tick += INTERVAL
        if next_tick < tick_now:
            next_tick = tick_now + INTERVAL

        cur = psi("io"), psi("memory"), psi("cpu")
        d = []
        for name, c, p in zip(("io", "mem", "cpu"), cur, last_psi):
            d.append("%s=%.0fms(a10 %.1f)" % (
                name, (c["some"][1] - p["some"][1]) / 1000, c["some"][0]))
        last_psi = cur

        procs = []
        for comm in ("Hyprland", "noctalia"):
            pid = pids.get(comm) or find_pid(comm)
            pids[comm] = pid
            st = proc_stat(pid) if pid else None
            if st is None:
                pids[comm] = None
                procs.append("%s=gone" % comm)
                continue
            prev = last_stat.get(comm)
            last_stat[comm] = st
            dcpu = ((st[1] - prev[1]) / CLK_TCK * 1000) if prev else 0
            dflt = (st[2] - prev[2]) if prev else 0
            procs.append("%s[%s cpu=%.0fms majflt=%d]" % (comm, st[0], dcpu, dflt))

        ipc_max = ipc.get("max", 0)
        ipc["max"] = 0
        log("t+%5.1fs jit=%.0fms freq=%.0fMHz ipcmax=%.0fms psi %s load=%s %s"
            % (tick_now - t0, jitter_ms, mean_freq_mhz(), ipc_max, " ".join(d),
               read("/proc/loadavg").split()[0], " ".join(procs)))

    stop.set()
    log("probe: done keys_seen=%d" % first_key_logged)


if __name__ == "__main__":
    main()
