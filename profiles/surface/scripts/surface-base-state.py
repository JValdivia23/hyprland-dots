#!/usr/bin/env python3
"""Publish physical Surface Book 3 base status without exposing latch control."""

import fcntl
import json
import os
from pathlib import Path
import select
import signal
import struct
import sys


DEVICE = "/dev/surface/dtx"
STATE = Path("/run/surface-base-state/state.json")
EVENTS_ENABLE = 0xA521
GET_BASE_INFO = 0x8004A529
BASE_CONNECTION = 3


def decode_base(payload):
    if len(payload) != 4:
        raise ValueError("Invalid DTX base-info length")
    state, base_id = struct.unpack("=HH", payload)
    # NOT_FEASIBLE (low tablet battery) still means a base is attached.
    attached = True if state in (1, 0x1001) else None
    # The SSH driver ORs its type tag into even an absent (zero) base ID.
    if state == 0 and base_id in (0, 0x0200):
        attached = False
    return {"attached": attached, "base_state": state, "base_id": base_id}


def consume_events(buffer):
    events = []
    while len(buffer) >= 4:
        length, code = struct.unpack_from("=HH", buffer)
        if length > 4096:
            raise ValueError("Invalid DTX event length")
        if len(buffer) < 4 + length:
            break
        events.append((code, bytes(buffer[4:4 + length])))
        del buffer[:4 + length]
    return events


def publish(value):
    temporary = STATE.with_suffix(".tmp")
    with temporary.open("w") as stream:
        os.fchmod(stream.fileno(), 0o644)
        json.dump(value, stream)
        stream.write("\n")
    temporary.replace(STATE)
    print(json.dumps(value), flush=True)


def stop(_signum, _frame):
    raise SystemExit(0)


def main():
    if Path("/sys/class/dmi/id/product_name").read_text().strip() != "Surface Book 3":
        raise SystemExit("This status service is only for Surface Book 3")
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    fd = os.open(DEVICE, os.O_RDONLY | os.O_NONBLOCK | os.O_CLOEXEC)
    try:
        # These are the only IOCTLs used: enable this subscriber and read status.
        # No latch request, confirmation, lock, unlock, or heartbeat is sent.
        fcntl.ioctl(fd, EVENTS_ENABLE)
        initial = bytearray(4)
        fcntl.ioctl(fd, GET_BASE_INFO, initial, True)
        publish(decode_base(initial))
        poller = select.poll()
        poller.register(fd, select.POLLIN | select.POLLHUP | select.POLLERR)
        buffer = bytearray()
        while True:
            for _, flags in poller.poll():
                if flags & (select.POLLHUP | select.POLLERR | select.POLLNVAL):
                    raise OSError("DTX device disconnected")
                data = os.read(fd, 4096)
                if not data:
                    raise OSError("DTX device returned EOF")
                buffer.extend(data)
                for code, payload in consume_events(buffer):
                    if code == BASE_CONNECTION:
                        publish(decode_base(payload))
    finally:
        os.close(fd)
        publish({"attached": None, "base_state": None, "base_id": None})


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(f"surface-base-state: {error}", file=sys.stderr, flush=True)
        sys.exit(1)
