#!/usr/bin/env bash
# ==============================================================================
# surface-greeter-client - Runs inside Surface greetd Hyprland session
# Launches wvkbd-mobintl (hidden), lisgd bottom-up swipe gesture, and noctalia-greeter,
# then exits Hyprland cleanly as soon as noctalia-greeter finishes login.
# ==============================================================================
set -uo pipefail

GREETER_BIN="${GREETER_BIN:-/usr/bin/noctalia-greeter}"
DONE_FILE="${GREETER_DONE_FILE:-${XDG_RUNTIME_DIR:-/tmp}/noctalia-greeter-done}"

WVKBD_PID=""
LISGD_SUP_PID=""

cleanup() {
    if [[ -n "$LISGD_SUP_PID" ]]; then
        kill "$LISGD_SUP_PID" 2>/dev/null || true
    fi
    pkill -u "$(id -u)" -x lisgd 2>/dev/null || true
    if [[ -n "$WVKBD_PID" ]]; then
        kill "$WVKBD_PID" 2>/dev/null || true
    fi
    pkill -u "$(id -u)" -x wvkbd-mobintl 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# 1. Start wvkbd-mobintl in hidden mode (ready to toggle via SIGRTMIN)
if command -v wvkbd-mobintl >/dev/null 2>&1; then
    wvkbd-mobintl -L 320 -H 320 --hidden &
    WVKBD_PID=$!
fi

# 2. Start lisgd supervisor for 1-finger bottom-up swipe to toggle wvkbd-mobintl
if command -v lisgd >/dev/null 2>&1; then
    (
        TOGGLE_CMD="pkill -RTMIN -u $(id -u) -x wvkbd-mobintl || wvkbd-mobintl -L 320 -H 320 &"
        while true; do
            DEVICE_NODE=""
            for ((i = 0; i < 30; i++)); do
                DEVICE_NODE=$(grep -E -A 5 -B 1 "IPTSD Virtual Touchscreen" /proc/bus/input/devices 2>/dev/null | grep -o 'event[0-9]\+' | head -n1 || true)
                if [[ -z "$DEVICE_NODE" ]]; then
                    DEVICE_NODE=$(grep -E -A 5 -B 1 "IPTS .* Touchscreen" /proc/bus/input/devices 2>/dev/null | grep -o 'event[0-9]\+' | head -n1 || true)
                fi
                if [[ -n "$DEVICE_NODE" && -r "/dev/input/${DEVICE_NODE}" ]]; then
                    break
                fi
                sleep 0.2
            done

            if [[ -z "$DEVICE_NODE" || ! -r "/dev/input/${DEVICE_NODE}" ]]; then
                sleep 1
                continue
            fi

            DEVICE_PATH="/dev/input/${DEVICE_NODE}"
            lisgd -d "$DEVICE_PATH" \
                -w 3000 \
                -h 2000 \
                -s 3.5 \
                -r 20 \
                -t 80 \
                -m 1500 \
                -g "1,DU,B,*,R,${TOGGLE_CMD}" \
                -g "1,DU,BL,*,R,${TOGGLE_CMD}" \
                -g "1,DU,BR,*,R,${TOGGLE_CMD}" &
            LPID=$!

            while kill -0 "$LPID" 2>/dev/null; do
                sleep 2
                if ! readlink /proc/"$LPID"/fd/* 2>/dev/null | grep -Fxq "$DEVICE_PATH"; then
                    kill "$LPID" 2>/dev/null || true
                    break
                fi
            done
            wait "$LPID" 2>/dev/null || true
            sleep 0.5
        done
    ) &
    LISGD_SUP_PID=$!
fi

# Mark compositor startup healthy so surface-greeter-session does not trigger fallback
touch "$DONE_FILE" 2>/dev/null || true

# 3. Run noctalia-greeter in the foreground
if [[ -n "${GREETER_ARGS:-}" ]]; then
    # shellcheck disable=SC2086
    "$GREETER_BIN" $GREETER_ARGS
else
    "$GREETER_BIN"
fi

# 4. Clean up helper daemons and exit Hyprland so greetd starts the user session
cleanup
hyprctl eval 'hl.dispatch(hl.dsp.exit())' >/dev/null 2>&1 || hyprctl dispatch exit >/dev/null 2>&1 || true
