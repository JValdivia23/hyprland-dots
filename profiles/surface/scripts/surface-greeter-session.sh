#!/usr/bin/env sh
# ==============================================================================
# surface-greeter-session - Surface Book 3 greetd wrapper for noctalia-greeter
# Runs noctalia-greeter inside a minimal Hyprland compositor so wvkbd-mobintl
# (wlr-layer-shell + virtual-keyboard) and lisgd 1-finger bottom-up swipe
# gestures work before login in tablet mode.
# Automatically falls back to /usr/bin/noctalia-greeter-session if Hyprland
# is unavailable or fails to initialize.
# ==============================================================================
set -eu

GREETER_BIN="${NOCTALIA_GREETER_BIN:-/usr/bin/noctalia-greeter}"
HYPR_CFG="${SURFACE_GREETER_HYPR_CFG:-/etc/greetd/surface-hyprland.lua}"

# Fall back immediately if Hyprland, client script, or config is missing
if ! command -v Hyprland >/dev/null 2>&1 || [ ! -x /usr/local/bin/surface-greeter-client ] || [ ! -f "${HYPR_CFG}" ]; then
    exec /usr/bin/noctalia-greeter-session "$@"
fi

# Park stdout/stderr unless NOCTALIA_GREETER_LOG is explicitly requested
case "${NOCTALIA_GREETER_LOG:-}" in
"" )
    exec >/dev/null 2>&1
    unset NOCTALIA_GREETER_LOG
    ;;
- | none | NONE | stderr | STDERR | stdout | STDOUT)
    export NOCTALIA_GREETER_LOG=stderr
    ;;
*)
    _log_target="${NOCTALIA_GREETER_LOG}"
    if touch "${_log_target}" 2>/dev/null; then
        exec >>"${_log_target}" 2>&1
        export NOCTALIA_GREETER_LOG="${_log_target}"
    else
        exec >/dev/null 2>&1
        unset NOCTALIA_GREETER_LOG
    fi
    ;;
esac

if [ -z "${XDG_RUNTIME_DIR:-}" ] || [ ! -d "${XDG_RUNTIME_DIR}" ]; then
    XDG_RUNTIME_DIR="/tmp/noctalia-runtime-$(id -u)"
    export XDG_RUNTIME_DIR
    mkdir -p "${XDG_RUNTIME_DIR}"
    chmod 700 "${XDG_RUNTIME_DIR}"
fi

unset WAYLAND_DISPLAY

GREETER_DONE_FILE="${XDG_RUNTIME_DIR}/noctalia-greeter-done"
rm -f "${GREETER_DONE_FILE}"

export GREETER_BIN
export GREETER_DONE_FILE
export GREETER_ARGS="$*"

if command -v dbus-run-session >/dev/null 2>&1; then
    dbus-run-session -- Hyprland -c "${HYPR_CFG}" || true
else
    Hyprland -c "${HYPR_CFG}" || true
fi

# Fail-safe: if Hyprland exited before surface-greeter-client started noctalia-greeter,
# fall back to the stock wlroots noctalia-greeter-session so login is never blocked.
if [ ! -f "${GREETER_DONE_FILE}" ]; then
    exec /usr/bin/noctalia-greeter-session "$@"
fi
rm -f "${GREETER_DONE_FILE}"
