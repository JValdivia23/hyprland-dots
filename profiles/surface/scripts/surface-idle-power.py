#!/usr/bin/env python3
"""surface-idle-power: measure and track idle battery draw on the Surface Book 3.

Sums power_now of BOTH batteries (tablet BAT1 + keyboard-base BAT2) over a quiet
window while on battery, together with the conditions that make runs comparable
(kernel, power profile, brightness, per-state C-state residency, busiest
processes). Every run is appended to ~/.local/state/surface-idle-power/log.jsonl
so kernel / package updates can be compared against earlier baselines.

Needs no root. Run it, then leave the machine alone until it finishes.

    surface-idle-power.py --label "7.2.11 baseline"
    surface-idle-power.py --history
"""
import argparse
import glob
import json
import os
import platform
import shutil
import statistics
import subprocess
import sys
import time
from datetime import datetime

PS = "/sys/class/power_supply"
LOG = os.path.expanduser("~/.local/state/surface-idle-power/log.jsonl")
NOISY_CORE_PCT = 5.0  # a single process above this makes the window "noisy"


def rd(path, default=None):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def rd_int(path):
    try:
        return int(rd(path))
    except (TypeError, ValueError):
        return None


def supplies():
    bats, mains = [], []
    for d in sorted(glob.glob(f"{PS}/*")):
        kind = rd(f"{d}/type")
        if kind == "Battery":
            bats.append(d)
        elif kind == "Mains":
            mains.append(d)
    return bats, mains


def ac_online(mains):
    return any(rd(f"{m}/online") == "1" for m in mains)


def battery_power_uw(bats):
    total = 0
    for b in bats:
        p = rd_int(f"{b}/power_now")
        if p is None:
            c, v = rd_int(f"{b}/current_now"), rd_int(f"{b}/voltage_now")
            p = abs(c) * v // 10**6 if c is not None and v is not None else 0
        total += p
    return total


def battery_energy_uwh(bats):
    total = 0
    for b in bats:
        e = rd_int(f"{b}/energy_now")
        if e is None:
            c, v = rd_int(f"{b}/charge_now"), rd_int(f"{b}/voltage_now")
            if c is None or v is None:
                return None
            e = c * v // 10**6
        total += e
    return total


def cpu_stat():
    vals = list(map(int, rd("/proc/stat").splitlines()[0].split()[1:]))
    return sum(vals[:8]), vals[3] + vals[4]


def cpuidle_us():
    snap = {}
    for st in glob.glob("/sys/devices/system/cpu/cpu[0-9]*/cpuidle/state*"):
        name, t = rd(f"{st}/name"), rd_int(f"{st}/time")
        if name is not None and t is not None:
            snap[name] = snap.get(name, 0) + t
    return snap


def proc_ticks():
    out = {}
    for d in os.listdir("/proc"):
        if not d.isdigit() or int(d) == os.getpid():
            continue
        try:
            with open(f"/proc/{d}/stat") as f:
                s = f.read()
        except OSError:
            continue
        r = s.rfind(")")
        comm = s[s.find("(") + 1:r]
        fields = s[r + 2:].split()
        out[int(d)] = (comm, int(fields[11]) + int(fields[12]))
    return out


def brightness_pct():
    for d in glob.glob("/sys/class/backlight/*"):
        b, m = rd_int(f"{d}/brightness"), rd_int(f"{d}/max_brightness")
        if b is not None and m:
            return 100.0 * b / m
    return None


def avg_freq_mhz():
    f = [rd_int(p) for p in glob.glob("/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq")]
    f = [x for x in f if x]
    return sum(f) / len(f) / 1000 if f else None


def powerprofile():
    try:
        return subprocess.run(["powerprofilesctl", "get"], capture_output=True,
                              text=True, timeout=3).stdout.strip() or None
    except (OSError, subprocess.SubprocessError):
        return None


def history():
    if not os.path.exists(LOG):
        print("No runs recorded yet.")
        return
    print("| Date | Kernel | Label | Median W | Mean W | Energy-delta W | Flags |")
    print("|---|---|---|---|---|---|---|")
    for line in open(LOG):
        r = json.loads(line)
        e = r.get("energy_delta_w")
        print(f"| {r['date']} | {r['kernel']} | {r.get('label') or '-'} | {r['median_w']:.2f} | "
              f"{r['mean_w']:.2f} | {'n/a' if e is None else f'{e:.2f}'} | "
              f"{', '.join(r['flags']) or 'clean'} |")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--settle", type=int, default=60, help="seconds to wait before measuring (default 60)")
    ap.add_argument("--duration", type=int, default=300, help="measurement window in seconds (default 300)")
    ap.add_argument("--interval", type=int, default=5, help="seconds between samples (default 5)")
    ap.add_argument("--label", default="", help="free-text note stored with the run")
    ap.add_argument("--no-log", action="store_true", help="do not append the run to the log")
    ap.add_argument("--allow-ac", action="store_true", help="measure even while on AC (draw is then meaningless)")
    ap.add_argument("--no-inhibit", action="store_true",
                    help="do not hold a systemd idle inhibitor (hypridle will then dim/blank the screen mid-run)")
    ap.add_argument("--history", action="store_true", help="print past runs and exit")
    a = ap.parse_args()

    if a.history:
        history()
        return 0

    bats, mains = supplies()
    if not bats:
        print("No battery found.", file=sys.stderr)
        return 2
    if ac_online(mains) and not a.allow_ac:
        print("AC is connected: unplug it and retry (or use --allow-ac).", file=sys.stderr)
        return 2

    # hypridle (ignore_systemd_inhibit = false) dims at 150s and blanks at 300s of idle, which would
    # change the screen state mid-run. Re-exec under an idle inhibitor so every run is comparable.
    if not a.no_inhibit and os.environ.get("SURFACE_IDLE_POWER_INHIBITED") != "1" and shutil.which("systemd-inhibit"):
        env = dict(os.environ, SURFACE_IDLE_POWER_INHIBITED="1")
        os.execvpe("systemd-inhibit", [
            "systemd-inhibit", "--what=idle", "--who=surface-idle-power",
            "--why=Idle power measurement (keep screen state constant)",
            sys.executable, os.path.abspath(__file__), *sys.argv[1:]], env)

    print(f"Settling {a.settle}s, then measuring {a.duration}s every {a.interval}s. Leave the machine idle.",
          flush=True)
    time.sleep(a.settle)

    nproc = os.cpu_count() or 1
    hz = os.sysconf("SC_CLK_TCK")
    t0, (tot0, idle0) = time.time(), cpu_stat()
    idle_states0, ticks0 = cpuidle_us(), proc_ticks()
    energy0 = battery_energy_uwh(bats)

    watts, bright, freqs, flags = [], [], [], []
    while time.time() - t0 < a.duration:
        if ac_online(mains):
            flags.append("ac-connected-during-run")
        watts.append(battery_power_uw(bats) / 1e6)
        b = brightness_pct()
        if b is not None:
            bright.append(b)
        f = avg_freq_mhz()
        if f:
            freqs.append(f)
        time.sleep(a.interval)

    wall = time.time() - t0
    tot1, idle1 = cpu_stat()
    idle_states1, ticks1 = cpuidle_us(), proc_ticks()
    energy1 = battery_energy_uwh(bats)

    cpu_idle_pct = 100.0 * (idle1 - idle0) / max(tot1 - tot0, 1)
    residency = {n: 100.0 * (idle_states1[n] - idle_states0.get(n, 0)) / (wall * 1e6 * nproc)
                 for n in idle_states1}

    per_comm = {}
    for pid, (comm, t1) in ticks1.items():
        t0p = ticks0[pid][1] if pid in ticks0 else 0
        per_comm[comm] = per_comm.get(comm, 0) + max(t1 - t0p, 0)
    top = sorted(((100.0 * v / hz / wall, c) for c, v in per_comm.items()), reverse=True)[:5]

    energy_w = None
    if energy0 is not None and energy1 is not None and energy0 > energy1:
        energy_w = (energy0 - energy1) / 1e6 / (wall / 3600)  # µWh -> Wh over hours = W

    if top and top[0][0] >= NOISY_CORE_PCT:
        flags.append(f"noisy:{top[0][1]}={top[0][0]:.0f}%core")
    if bright and max(bright) - min(bright) > 1.0:
        flags.append("brightness-changed")
    if any(rd(f"{b}/status") not in ("Discharging", "Not charging") for b in bats):
        flags.append("battery-not-discharging")
    up = float(rd("/proc/uptime").split()[0])
    if up < 600:
        flags.append("uptime<10min")

    rec = {
        "date": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "kernel": platform.release(),
        "label": a.label,
        "duration_s": round(wall),
        "samples": len(watts),
        "median_w": statistics.median(watts),
        "mean_w": statistics.fmean(watts),
        "stdev_w": statistics.pstdev(watts),
        "min_w": min(watts),
        "max_w": max(watts),
        "energy_delta_w": energy_w,
        "cpu_idle_pct": cpu_idle_pct,
        "avg_mhz": statistics.fmean(freqs) if freqs else None,
        "cstate_residency_pct": {k: round(v, 1) for k, v in residency.items()},
        "top_cpu": [{"comm": c, "core_pct": round(p, 2)} for p, c in top],
        "brightness_pct": round(statistics.fmean(bright), 1) if bright else None,
        "power_profile": powerprofile(),
        "governor": rd("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"),
        "epp": rd("/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference"),
        "battery_pct": [rd_int(f"{b}/capacity") for b in bats],
        "uptime_min": round(up / 60, 1),
        "flags": sorted(set(flags)),
    }

    print(f"\nIdle draw ({rec['samples']} samples / {rec['duration_s']}s) on {rec['kernel']}")
    print(f"  median {rec['median_w']:.2f} W   mean {rec['mean_w']:.2f} W   "
          f"stdev {rec['stdev_w']:.2f}   range {rec['min_w']:.2f}-{rec['max_w']:.2f} W")
    print("  energy-counter cross-check: " + (f"{energy_w:.2f} W" if energy_w is not None else "n/a (no delta)"))
    print(f"  CPU idle {cpu_idle_pct:.1f}%   avg {rec['avg_mhz'] or 0:.0f} MHz   "
          f"brightness {rec['brightness_pct']}%   profile {rec['power_profile']}/{rec['governor']}/{rec['epp']}")
    print("  C-state residency (% of all CPU time): " +
          ", ".join(f"{k} {v:.1f}" for k, v in rec["cstate_residency_pct"].items()))
    print("  busiest: " + ", ".join(f"{t['comm']} {t['core_pct']}%" for t in rec["top_cpu"]))
    print("  flags: " + (", ".join(rec["flags"]) or "clean"))

    if not a.no_log:
        os.makedirs(os.path.dirname(LOG), exist_ok=True)
        with open(LOG, "a") as f:
            f.write(json.dumps(rec) + "\n")
        print(f"  logged to {LOG}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
