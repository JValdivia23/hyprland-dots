#!/usr/bin/env python3
"""
Align CMOS rtc0 (PNP0B00:00) with the Surface Aggregator Module (SAM) EC
UEFI POST clock epoch across S5 hibernation (HibernateMode=shutdown).

Root cause on Microsoft Surface Book 3:
- While Linux is awake with NTP (rtcsync) active, the kernel's 11-minute
  sync_hw_clock timer writes UTC to CMOS rtc0 (ports 0x70/0x71).
- Across S5 hibernation (HibernateMode=shutdown), Surface UEFI POST
  re-initializes CMOS rtc0 from the SAM EC real-time clock, which runs at
  UTC - 25,179s (~-7h, matching EFI variable RTC-378d7b65 offset 0x01a4 = 420m).
- At hibernation entry, timekeeping_suspend() records timekeeping_suspend_time
  from rtc0 (UTC). At hibernation exit, timekeeping_resume() reads ts_new from
  POST-reinitialized rtc0 (t_wake - 25,179s) and computes:
      delta = ts_new - timekeeping_suspend_time = T_hibernated - 25,179s
  * If T_hibernated < 7h: delta < 0 -> kernel rejects negative delta and
    injects 0s (system clock & CLOCK_BOOTTIME freeze at pre-hibernate time).
  * If T_hibernated > 7h: kernel injects T_hibernated - 25,179s (system wakes
    7 hours behind true UTC until chronyd steps the clock after Wi-Fi connects).

Fix (Option B):
- pre-hibernate:
  1. Optionally calibrate the stored SAM POST offset from the prior verified
     hibernation wake sample if NTP is currently synchronized (STA_UNSYNC == 0).
  2. Latch STA_UNSYNC (0x0040) via adjtimex() so the kernel's sync_hw_clock
     hrtimer cannot overwrite rtc0 back to UTC while hibernation snapshot
     memory is being preallocated before syscore_suspend()/timekeeping_suspend().
  3. Set CMOS rtc0 to (CLOCK_REALTIME + offset_sec) via ioctl(RTC_SET_TIME)
     so timekeeping_suspend() records timekeeping_suspend_time on the exact
     same epoch that UEFI POST will load into rtc0 at wake.
- post-hibernate:
  1. At syscore_resume(), timekeeping_resume() reads POST-initialized rtc0
     (t_wake + offset_sec) and subtracts timekeeping_suspend_time
     (t_sleep + offset_sec). The offsets cancel out and the kernel natively
     injects +T_hibernated into both CLOCK_REALTIME and CLOCK_BOOTTIME.
  2. Read raw POST rtc0 (for drift calibration and fallback verification),
     restore CMOS rtc0 back to UTC (CLOCK_REALTIME) via ioctl(RTC_SET_TIME),
     and restore STA_UNSYNC if NTP was previously synchronized.
"""

from __future__ import annotations

import calendar
import ctypes
import ctypes.util
import fcntl
import json
import os
import struct
import sys
import time
from pathlib import Path

# Default measured SAM EC UEFI POST offset on Surface Book 3 (seconds relative to UTC).
# Measured across Oct 13-18 2026: -25180.96s, -25179.77s, -25179.00s.
DEFAULT_SAM_OFFSET_SEC = -25179
# Validated window around -7h (-25200s +/- 300s) to prevent bogus calibration drift.
MIN_VALID_OFFSET_SEC = -25500
MAX_VALID_OFFSET_SEC = -24900

# Minimum sanity epoch (2023-11-14 UTC) to ensure CLOCK_REALTIME is valid.
MIN_VALID_EPOCH = 1700000000

# Linux <linux/rtc.h> ioctl constants for struct rtc_time (9 ints = 36 bytes)
RTC_RD_TIME = 0x80247009
RTC_SET_TIME = 0x4024700A

# Linux <sys/timex.h> constants
ADJ_STATUS = 0x0010
STA_UNSYNC = 0x0040


class Timex(ctypes.Structure):
    _fields_ = [
        ("modes", ctypes.c_uint),
        ("offset", ctypes.c_long),
        ("freq", ctypes.c_long),
        ("maxerror", ctypes.c_long),
        ("esterror", ctypes.c_long),
        ("status", ctypes.c_int),
        ("constant", ctypes.c_long),
        ("precision", ctypes.c_long),
        ("tolerance", ctypes.c_long),
        ("tv_sec", ctypes.c_long),
        ("tv_usec", ctypes.c_long),
        ("tick", ctypes.c_long),
        ("ppsfreq", ctypes.c_long),
        ("jitter", ctypes.c_long),
        ("shift", ctypes.c_int),
        ("stabil", ctypes.c_long),
        ("jitcnt", ctypes.c_long),
        ("calcnt", ctypes.c_long),
        ("errcnt", ctypes.c_long),
        ("stbcnt", ctypes.c_long),
        ("tai", ctypes.c_int),
        ("_pad", ctypes.c_int * 11),
    ]


def get_paths() -> dict[str, Path]:
    sysfs_dir = Path(os.environ.get("SURFACE_RTC_SYSFS_DIR", "/sys/class/rtc/rtc0"))
    state_dir = Path(os.environ.get("SURFACE_RTC_STATE_DIR", "/var/lib/surface-hibernate-rtc"))
    return {
        "dmi_product": Path(
            os.environ.get("SURFACE_DMI_PRODUCT_FILE", "/sys/class/dmi/id/product_name")
        ),
        "rtc_sysfs": sysfs_dir,
        "rtc_name": sysfs_dir / "name",
        "rtc_since_epoch": sysfs_dir / "since_epoch",
        "rtc_dev": Path(os.environ.get("SURFACE_RTC_DEV", "/dev/rtc0")),
        "boot_id": Path(
            os.environ.get("SURFACE_BOOT_ID_FILE", "/proc/sys/kernel/random/boot_id")
        ),
        "state_dir": state_dir,
        "offset_file": state_dir / "offset_sec",
        "wake_sample_file": state_dir / "last_wake_sample.json",
        "run_state": Path(
            os.environ.get("SURFACE_RTC_RUN_STATE", "/run/surface-hibernate-rtc.json")
        ),
    }


def is_surface_cmos_rtc(paths: dict[str, Path]) -> bool:
    try:
        product = paths["dmi_product"].read_text(encoding="utf-8").strip()
        rtc_name = paths["rtc_name"].read_text(encoding="utf-8").strip()
    except OSError:
        return False
    return product.startswith("Surface") and rtc_name.startswith("rtc_cmos")


def read_boot_id(paths: dict[str, Path]) -> str:
    try:
        return paths["boot_id"].read_text(encoding="utf-8").strip()
    except OSError:
        return "unknown"


def get_realtime() -> float:
    mock = os.environ.get("SURFACE_RTC_MOCK_REALTIME")
    if mock is not None:
        return float(mock)
    return time.time()


def get_boottime() -> float:
    mock = os.environ.get("SURFACE_RTC_MOCK_BOOTTIME")
    if mock is not None:
        return float(mock)
    return time.clock_gettime(time.CLOCK_BOOTTIME)


def set_realtime_fallback(target_epoch: float) -> bool:
    if os.environ.get("SURFACE_RTC_MOCK_MODE") == "1":
        mock_out = os.environ.get("SURFACE_RTC_MOCK_CLOCK_SETTIME_FILE")
        if mock_out:
            Path(mock_out).write_text(f"{target_epoch:.3f}\n", encoding="utf-8")
        return True
    try:
        time.clock_settime(time.CLOCK_REALTIME, target_epoch)
        return True
    except OSError as exc:
        print(f"Surface hibernate RTC warning: clock_settime failed: {exc}", file=sys.stderr)
        return False


def get_adjtimex_status() -> int | None:
    if os.environ.get("SURFACE_RTC_MOCK_MODE") == "1":
        status_file = os.environ.get("SURFACE_RTC_MOCK_ADJTIMEX_FILE")
        if status_file and Path(status_file).is_file():
            return int(Path(status_file).read_text(encoding="utf-8").strip())
        return 0
    libc_name = ctypes.util.find_library("c")
    if not libc_name:
        return None
    libc = ctypes.CDLL(libc_name, use_errno=True)
    tx = Timex()
    tx.modes = 0
    res = libc.adjtimex(ctypes.byref(tx))
    if res < 0:
        return None
    return int(tx.status)


def set_adjtimex_unsync(unsync: bool) -> bool:
    if os.environ.get("SURFACE_RTC_MOCK_MODE") == "1":
        status_file = os.environ.get("SURFACE_RTC_MOCK_ADJTIMEX_FILE")
        if status_file:
            cur = get_adjtimex_status() or 0
            new_status = (cur | STA_UNSYNC) if unsync else (cur & ~STA_UNSYNC)
            Path(status_file).write_text(f"{new_status}\n", encoding="utf-8")
        return True
    libc_name = ctypes.util.find_library("c")
    if not libc_name:
        return False
    libc = ctypes.CDLL(libc_name, use_errno=True)
    tx = Timex()
    tx.modes = 0
    if libc.adjtimex(ctypes.byref(tx)) < 0:
        return False
    tx.modes = ADJ_STATUS
    if unsync:
        tx.status |= STA_UNSYNC
    else:
        tx.status &= ~STA_UNSYNC
    return libc.adjtimex(ctypes.byref(tx)) >= 0


def read_rtc_epoch(paths: dict[str, Path]) -> int:
    return int(paths["rtc_since_epoch"].read_text(encoding="utf-8").strip())


def write_rtc_epoch(paths: dict[str, Path], epoch_sec: int) -> int:
    if os.environ.get("SURFACE_RTC_MOCK_MODE") == "1":
        paths["rtc_since_epoch"].write_text(f"{int(epoch_sec)}\n", encoding="utf-8")
        return int(epoch_sec)

    gm = time.gmtime(int(epoch_sec))
    # struct rtc_time: tm_sec, tm_min, tm_hour, tm_mday, tm_mon (0-11),
    # tm_year (years since 1900), tm_wday (0=Sun..6=Sat), tm_yday (0-365), tm_isdst
    tm_wday = (gm.tm_wday + 1) % 7
    payload = struct.pack(
        "9i",
        gm.tm_sec,
        gm.tm_min,
        gm.tm_hour,
        gm.tm_mday,
        gm.tm_mon - 1,
        gm.tm_year - 1900,
        tm_wday,
        gm.tm_yday - 1,
        0,
    )
    fd = os.open(str(paths["rtc_dev"]), os.O_RDONLY | os.O_CLOEXEC)
    try:
        fcntl.ioctl(fd, RTC_SET_TIME, payload)
    finally:
        os.close(fd)

    try:
        return read_rtc_epoch(paths)
    except OSError:
        return int(calendar.timegm(gm))


def load_offset_sec(paths: dict[str, Path]) -> int:
    try:
        val = int(paths["offset_file"].read_text(encoding="utf-8").strip())
        if MIN_VALID_OFFSET_SEC <= val <= MAX_VALID_OFFSET_SEC:
            return val
    except (OSError, ValueError):
        pass
    return DEFAULT_SAM_OFFSET_SEC


def save_offset_sec(paths: dict[str, Path], offset_sec: int) -> None:
    if not (MIN_VALID_OFFSET_SEC <= offset_sec <= MAX_VALID_OFFSET_SEC):
        return
    try:
        paths["state_dir"].mkdir(parents=True, exist_ok=True)
        tmp = paths["offset_file"].with_suffix(".tmp")
        tmp.write_text(f"{int(offset_sec)}\n", encoding="utf-8")
        tmp.replace(paths["offset_file"])
    except OSError as exc:
        print(f"Surface hibernate RTC warning: failed to save offset: {exc}", file=sys.stderr)


def maybe_calibrate_from_last_wake(
    paths: dict[str, Path],
    boot_id: str,
    sys_now: float,
    boot_now: float,
    ntp_synced: bool,
) -> int | None:
    sample_file = paths["wake_sample_file"]
    if not ntp_synced or not sample_file.is_file():
        return None
    try:
        sample = json.loads(sample_file.read_text(encoding="utf-8"))
        sample_file.unlink(missing_ok=True)
    except (OSError, ValueError, json.JSONDecodeError):
        return None

    if sample.get("boot_id") != boot_id:
        return None
    try:
        rtc_post = int(sample["rtc_post"])
        boot_post = float(sample["boot_epoch"])
    except (KeyError, TypeError, ValueError):
        return None

    elapsed_since_wake = boot_now - boot_post
    if elapsed_since_wake < 0:
        return None

    true_wake_utc = sys_now - elapsed_since_wake
    measured_offset = int(round(rtc_post - true_wake_utc))
    if MIN_VALID_OFFSET_SEC <= measured_offset <= MAX_VALID_OFFSET_SEC:
        save_offset_sec(paths, measured_offset)
        return measured_offset
    return None


def handle_pre(paths: dict[str, Path]) -> int:
    sys_now = get_realtime()
    if sys_now < MIN_VALID_EPOCH:
        print(
            f"Surface hibernate RTC pre-sync skipped: invalid CLOCK_REALTIME ({sys_now:.0f}).",
            file=sys.stderr,
        )
        return 0

    boot_now = get_boottime()
    rtc_before = read_rtc_epoch(paths)
    boot_id = read_boot_id(paths)

    status = get_adjtimex_status()
    ntp_synced = status is not None and (status & STA_UNSYNC) == 0

    calibrated = maybe_calibrate_from_last_wake(
        paths, boot_id=boot_id, sys_now=sys_now, boot_now=boot_now, ntp_synced=ntp_synced
    )
    offset_sec = calibrated if calibrated is not None else load_offset_sec(paths)
    if not paths["offset_file"].is_file():
        save_offset_sec(paths, offset_sec)

    # Latch STA_UNSYNC so the kernel's sync_hw_clock hrtimer cannot overwrite
    # rtc0 back to UTC while hibernate snapshot pages are being preallocated.
    set_adjtimex_unsync(True)

    # Re-read CLOCK_REALTIME right before setting rtc0 for sub-second freshness.
    sys_target_base = int(round(get_realtime()))
    target_rtc = sys_target_base + offset_sec
    rtc_after = write_rtc_epoch(paths, target_rtc)

    state = {
        "boot_id": boot_id,
        "pre_sys_epoch": sys_target_base,
        "pre_boot_epoch": round(boot_now, 3),
        "pre_rtc_epoch": rtc_before,
        "target_rtc_epoch": target_rtc,
        "readback_rtc_epoch": rtc_after,
        "offset_sec": offset_sec,
        "was_ntp_synced": ntp_synced,
    }
    try:
        paths["run_state"].parent.mkdir(parents=True, exist_ok=True)
        paths["run_state"].write_text(json.dumps(state) + "\n", encoding="utf-8")
    except OSError:
        pass

    cal_note = f", calibrated={calibrated}s" if calibrated is not None else ""
    print(
        f"Surface hibernate RTC pre-sync: shifted rtc0 {rtc_before} -> {rtc_after} "
        f"(sys={sys_target_base}, offset={offset_sec}s, ntp_synced={ntp_synced}{cal_note})."
    )
    return 0


def handle_post(paths: dict[str, Path]) -> int:
    rtc_post = read_rtc_epoch(paths)
    sys_post = get_realtime()
    boot_post = get_boottime()
    boot_id = read_boot_id(paths)

    state: dict = {}
    if paths["run_state"].is_file():
        try:
            state = json.loads(paths["run_state"].read_text(encoding="utf-8"))
        except (OSError, ValueError, json.JSONDecodeError):
            state = {}
        try:
            paths["run_state"].unlink(missing_ok=True)
        except OSError:
            pass

    offset_sec = int(state.get("offset_sec", load_offset_sec(paths)))
    if not (MIN_VALID_OFFSET_SEC <= offset_sec <= MAX_VALID_OFFSET_SEC):
        offset_sec = DEFAULT_SAM_OFFSET_SEC

    pre_sys = float(state.get("pre_sys_epoch", 0))
    pre_boot = float(state.get("pre_boot_epoch", 0))
    was_ntp_synced = bool(state.get("was_ntp_synced", True))

    # In both normal S5 UEFI POST wake and aborted hibernation, (rtc_post - offset_sec)
    # equals true UTC. Under Option B, timekeeping_resume() already injected the delta
    # so sys_post is already ~equal to (rtc_post - offset_sec).
    expected_utc = float(rtc_post - offset_sec)
    fallback_step = 0.0
    if (
        expected_utc >= MIN_VALID_EPOCH
        and (expected_utc - sys_post) > 30.0
        and (pre_sys <= 0 or expected_utc > pre_sys + 15.0)
    ):
        fallback_step = expected_utc - sys_post
        if set_realtime_fallback(expected_utc):
            sys_post = get_realtime()

    # Restore CMOS rtc0 back to UTC immediately.
    utc_target = int(round(get_realtime()))
    rtc_restored = write_rtc_epoch(paths, utc_target)

    if was_ntp_synced:
        set_adjtimex_unsync(False)

    boot_delta = (boot_post - pre_boot) if pre_boot > 0 else 0.0
    # Save wake sample for drift calibration if this was a real hibernation cycle.
    if (
        boot_delta >= 15.0
        and fallback_step == 0.0
        and abs((rtc_post - sys_post) - offset_sec) <= 600.0
    ):
        sample = {
            "boot_id": boot_id,
            "rtc_post": rtc_post,
            "boot_epoch": round(boot_post, 3),
            "sys_post": round(sys_post, 3),
        }
        try:
            paths["state_dir"].mkdir(parents=True, exist_ok=True)
            tmp = paths["wake_sample_file"].with_suffix(".tmp")
            tmp.write_text(json.dumps(sample) + "\n", encoding="utf-8")
            tmp.replace(paths["wake_sample_file"])
        except OSError:
            pass

    step_note = (
        f", fallback_clock_step=+{fallback_step:.1f}s" if fallback_step > 0 else ""
    )
    print(
        f"Surface hibernate RTC post-sync: wake boot_delta=+{boot_delta:.1f}s, "
        f"rtc_post={rtc_post}, sys_post={sys_post:.0f}, restored rtc0 -> {rtc_restored} UTC"
        f"{step_note}."
    )
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] not in ("pre", "post", "status"):
        print(f"Usage: {argv[0]} <pre|post|status>", file=sys.stderr)
        return 2

    paths = get_paths()
    if not is_surface_cmos_rtc(paths):
        return 0

    phase = argv[1]
    if phase == "status":
        rtc_now = read_rtc_epoch(paths)
        sys_now = get_realtime()
        offset_sec = load_offset_sec(paths)
        status = get_adjtimex_status()
        ntp_synced = status is not None and (status & STA_UNSYNC) == 0
        print(
            json.dumps(
                {
                    "rtc0_epoch": rtc_now,
                    "sys_epoch": round(sys_now, 3),
                    "rtc_minus_sys_sec": round(rtc_now - sys_now, 3),
                    "configured_sam_offset_sec": offset_sec,
                    "ntp_synced": ntp_synced,
                },
                indent=2,
            )
        )
        return 0
    if phase == "pre":
        return handle_pre(paths)
    return handle_post(paths)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
