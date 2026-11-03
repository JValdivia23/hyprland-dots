# Surface Book 3: Detached-Only Screen Rotation

## Scope and policy

This is **Surface Book 3 hardware-specific** configuration in `profiles/surface/`.
It must not be moved to `core/` or enabled on the MacBook.

- Physically detached base: claim the accelerometer and automatically orient `eDP-1`.
- Any attached base, including a backwards/studio-mode attachment: landscape, rotation disabled.
- Missing, invalid, or unknown base status: landscape, rotation disabled.
- External monitors and non-IPTS input devices are not modified.
- Monitor rules are changed with Hyprland's **Lua API**; mode, scale and other existing rule fields are preserved.

## Why the generic tablet switch is insufficient

`Microsoft Surface DTX Device Mode Switch` reports `SW_TABLET_MODE` for both a
detached screen and a backwards-attached base. Watching that switch alone would
violate the requested detached-only behavior.

The kernel DTX interface `/dev/surface/dtx` provides actual base-connection
information. It is root-only and also exposes latch controls. **Do not grant
`uaccess`, change its mode, or add the user to an input group just for rotation.**

The restricted system service `surface-base-state.service` opens the interface
read-only, enables only its own event subscription, reads initial base status,
and publishes base-connection events to `/run/surface-base-state/state.json`.
It never requests, confirms, unlocks, locks or acknowledges detachment. The
world-readable status file contains only connection state and base ID; its
directory and files remain root-owned and non-writable by ordinary users.
The runtime directory is removed by systemd when the service stops.

Only a base state of `0` **and** an absent base ID (`0`, or `0x0200` with the
kernel SSH type tag) enables rotation. The kernel driver unconditionally ORs
`SDTX_DEVICE_TYPE_SSH` into IDs, including an absent zero ID, despite the UAPI
comment describing a plain zero. Do not reject `0x0200` as an attached base. The
`DETACH_NOT_FEASIBLE` low-tablet-battery status still means attached.

## Components

| Source | Deployed path / purpose |
|---|---|
| `scripts/surface-base-state.py` | `/usr/local/libexec/surface-base-state.py`, root-owned read-only status broker |
| `systemd/surface-base-state.service` | `/etc/systemd/system/surface-base-state.service`, enabled at boot |
| `scripts/install-rotation.sh` | Guarded, rotation-only deployment; deliberately does not run full `setup.sh` |
| `.local/bin/surface-autorotate` | `~/.local/bin/surface-autorotate`, session controller |
| `.config/systemd/user/surface-autorotate.service` | Session-bound user service; restores landscape on stop |
| `.config/hypr/config/profile/autostart.lua` | Starts the user service on Hyprland startup |
| `scripts/test-rotation.py` | Mocked tests; no hardware access or live rotation |

Prerequisites: `iio-sensor-proxy`, Python and `python-gobject`.

### Reinstall persistence

All runtime sources are stored in this profile; no `/tmp/opencode` deployment
artifact is needed to reinstall. Run `bash ./install.sh --profile surface` as the
regular desktop user from a fresh clone, then log into Hyprland. The master
installer installs profile packages and stows the helpers and user units before
`setup.sh` invokes the guarded root installer. Setup enables the rotation user
unit when the user service manager is available; the Surface Lua startup hook
also starts it on login. Do not use `--only-stow` for a fresh OS installation.

**GNU Stow gotcha:** a local ignore rule `^systemd` is a basename pattern, so it
also hides `.config/systemd/user/` and silently omits session units. The Surface
profile uses the root-relative path pattern `^/systemd` instead, excluding only
the system-service source directory. The master's command-line `--ignore=^systemd`
already matches a package-relative path and remains unchanged.

The controller debounces orientation changes for 400 ms, cancels queued changes
on reattachment, and checks the root-owned base state immediately before every
rotation. Flat/undefined orientations keep the last stable orientation.
It releases the accelerometer on attachment and before sleep. After resume it
allows 750 ms for DTX state reconciliation, then rereads attachment state.
Hyprland configuration reloads trigger reapplication of the current policy.

Base changes use filesystem notifications, with a two-second status-file check
to recover from broker restarts. **There is no periodic sensor polling or
recurring Hyprland query while attached.**

## Touch, pen, edge gestures and resizing

Rotating only the display leaves touch input incorrectly mapped. The controller
updates only IPTS/IPTSD touch and pen device rules together with `eDP-1`.
Input device rules remain valid if iptsd recreates its evdev nodes after sleep.

The verified display transform, native pixel dimensions and scale are published
under `$XDG_RUNTIME_DIR/surface-autorotate/`:

- `transform`: integer `0..3`, for the `hypr-lisgd` supervisor.
- `geometry.json`: dimensions/scale/transform, for the touch resizer.

`lisgd` has its own libinput context and does not inherit Hyprland's calibration.
Keep its **native** `-w 3000 -h 2000` dimensions to avoid the known startup
Wayland-socket crash. Its `-o` value is the **inverse** display transform:
`(4 - transform) % 4`, since lisgd rotates configured gesture directions and
edges into raw sensor coordinates. The controller signals only the user
service's supervisor with `USR1` to reconnect its child after rotation; the
existing two-second node/rotation checks provide a fallback.

`hypr-touch-resizer` reads real touch-axis ranges with `EVIOCGABS`, rotates
normalized motion deltas, and scales them to the rotated logical display. It
refreshes geometry while resizing and clears accumulated motion when it changes,
avoiding jumps. Its exclusive input grab remains restricted to resize mode.
The layer-shell keyboard follows the output geometry; no global keyboard or
Noctalia configuration is changed.

## Diagnostics

```fish
cat /run/surface-base-state/state.json
systemctl status surface-base-state.service
systemctl --user status surface-autorotate.service
journalctl --user -u surface-autorotate.service -b
hyprctl monitors -j
hyprctl configerrors
cat $XDG_RUNTIME_DIR/surface-autorotate/geometry.json
```

`attached: true` must not claim the accelerometer, even with the base attached
backwards. Missing status or `attached: null` intentionally disables rotation.
`monitor-sensor --accel` is an optional diagnostic that itself claims the sensor;
stop it before checking attached-mode power behavior.

Run non-interactive regression tests:

```fish
python3 -B ~/dotfiles/profiles/surface/scripts/test-rotation.py
```

## Rollback

Disable only the user rotation service:

```fish
systemctl --user disable --now surface-autorotate.service
```

Also remove its single startup command from the Surface profile's
`autostart.lua` if disabling persistently. Its `ExecStopPost` restores landscape
and IPTS mappings; `surface-autorotate --reset` can also restore them manually.
The read-only system broker may then be disabled separately. Do not revert
unrelated monitor, boot, sleep, IPTS recovery or Noctalia settings.

## Validation status

2026-10-19: deployed and enabled; 26 mocked tests, syntax/unit checks, installed
hashes, attached-mode landscape lock and accelerometer availability pass. Actual
IPTSD touch-axis range queries return 9600x7200. The package's udev reload
coincided with iptsd stopping; the existing recovery service restored it and both
virtual inputs without configuration edits. The gesture supervisor also now
exits on SIGTERM instead of looping until systemd's stop timeout.

**User confirmed the physical detach/rotate/touch/keyboard-swipe/reattach test
works.** The journal verifies a detached base ID of `512` (`0x0200`), both
portrait orientations (`3`, `1`), normal orientation (`0`), and physical
reattachment with ID `527`. Post-test the display is landscape at its original
3000x2000/scale 2, both IPTSD virtual inputs are present, all session helpers are
active and compositor validation is clean. Upside-down orientation `2` has
mocked coverage but was not separately observed in this journal. Physical pen,
backwards attachment, reboot and resume remain untested.

No post-change idle-power benchmark has been run; do not compare unmeasured
new-service drain with the earlier 5.86 W baseline. Deployment evidence is under
`/tmp/opencode/surface-rotation-jp10ozwy/`.
