# System Personalization Changelog

A dated log of all package changes, configurations, script modifications, and hardware setups for `surface`.

## [2.68.0] - 2026-10-19
### Added
- **Surface Book 3 Dual-Battery Idle Energy Tracking & Linux 7.2.11 Baseline (`profiles/surface`, device-specific)**:
  - Created unprivileged Python 3 profiling tool [`surface-idle-power.py`](file:///home/jmvp/dotfiles/profiles/surface/scripts/surface-idle-power.py) in `profiles/surface/scripts/` to measure dual-battery (`BAT1` + `BAT2`) discharge rates with automated quality filters and metadata logging (`~/.local/state/surface-idle-power/log.jsonl`).
  - **Screen State Consistency & Idle Inhibition**: Integrated automated `systemd-inhibit --what=idle` execution to prevent `hypridle` from stepping down backlight brightness (10% at 150s) or triggering DPMS off (at 300s) mid-measurement, ensuring uniform 25% brightness across 5-minute sampling runs.
  - **Baseline Established on `7.2.11-1-cachyos`**:
    - **Median draw**: **5.86 W** (mean: 5.91 W, stdev: 0.14 W, min: 5.75 W, max: 6.47 W).
    - **CPU & Thermal State**: 99.1% CPU idle, 716 MHz average core clock, 95.5% C3_ACPI state residency under `power-saver`/`powersave`/`power` EPP.
    - **Energy Counter Cross-Check**: Verified close agreement (5.62 W calculated via `energy_now` delta vs 5.86 W `power_now` median).
  - Created [`gotchas/power-baseline.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/power-baseline.md) (symlinked to skill gotchas) documenting measurement protocol, comparability gotchas, past run tables, and guidelines for validating the upcoming Linux 7.3 kernel.
  - Updated `SKILL.md` and `references/current-state.md`.

## [2.67.0] - 2026-10-19
### Changed
- **Full System Upgrade (`surface`, device-specific & core)**:
  - Upgraded system packages via `pacman -Syu`:
    - **Kernels**: `linux-cachyos` (7.2.9-2 $\rightarrow$ 7.2.11-1), `linux-cachyos-headers` (7.2.9-2 $\rightarrow$ 7.2.11-1), `linux-surface` (6.19.8.arch1-3 $\rightarrow$ 7.2.11.arch1-1), `linux-surface-headers` (6.19.8.arch1-3 $\rightarrow$ 7.2.11.arch1-1).
    - **Core System & Desktop**: `systemd` (262-1 $\rightarrow$ 262.1-1), `noctalia` (5.2.1-1.1 $\rightarrow$ 5.3.0-1.1), `iptsd` (3.1.0-1 $\rightarrow$ 3.1.1-1), `zen-browser-bin` (1.23.2b-1 $\rightarrow$ 1.23.3b-1), `hyprland-protocols` (0.7.1-1.1 $\rightarrow$ 0.8.0-1.1), `dkms` (3.4.3-1 $\rightarrow$ 3.4.4-2), `clang`/`llvm` (23.1.1 $\rightarrow$ 23.1.3-2).
  - **DKMS Module Verification**: Automatic DKMS build successfully compiled and installed `ipts/2024.04.16` for `7.2.11-1-cachyos` with Clang/LLVM.
  - **Bootloader & Snapshots**: Initramfs successfully generated and synced to `/boot` via `limine-snapper-sync` and `limine-mkinitcpio-hook`; Btrfs snapshot #64 created cleanly.
  - Updated `SKILL.md` to reference `camera-ipu4.md` and updated `references/current-state.md`.

## [2.66.0] - 2026-10-18
### Documented
- **Internal camera diagnosis (`surface` profile, device-specific)**: Confirmed no `/dev/video*`; ISP `8086:8a19` (Intel IPU4) has no bound driver on kernel `7.2.9-2-cachyos`, and IPU4 is unsupported upstream and in `linux-surface`. No fix; use an external USB UVC webcam. No system changes made. Added `references/gotchas/camera-ipu4.md`.

## [2.65.0] - 2026-10-18
### Added & Fixed
- **Minimized Window Tray Drawer UX, Full-Bleed Dynamic Badge Icons & State Sync (`core/`, universal)**:
  - **Root Cause of Tiny Tray Icon & Missing Count Badge**:
    - `/usr/share/icons/Adwaita/symbolic/ui/window-restore-symbolic.svg` uses a `6x6` square inside a `16x16` viewBox (`37.5%` linear size / `14%` area fill, designed for titlebar buttons), rendering as a tiny `~5.7px × 5.7px` speck inside Noctalia's `16px` (`15.2px` at `ui_scale = 0.95`) tray slot.
    - `AyatanaAppIndicator3.Indicator.set_label()` uses Canonical's `XAyatanaLabel` D-Bus property, which Noctalia's `StatusNotifierHost` does not implement, leaving the window count invisible on the bar.
    - Disassembly of `/usr/bin/noctalia` (`TrayWidget`, `0x127e140` & `0x12863d2`) showed that Noctalia indexes `IconThemePath` recursively upon SNI registration, invalidates its per-item icon cache when `IconName` changes (`0x127f53f`), and rasterizes `*-symbolic.svg` via `librsvg` (`rsvg_handle_new_from_data`), automatically tinting the SVG foreground to match the active theme's `on_secondary` tray capsule color.
  - **Full-Bleed `64x64` Dynamic SVG Badge Icons**:
    - Updated `core/.local/bin/hypr-tray-drawer` (`ensure_tray_icons()`) to pre-generate 11 full-bleed `64x64` vector SVG badge icons (`hypr-tray-drawer-{0..9,9plus}-symbolic.svg`) in `$XDG_RUNTIME_DIR/hypr-tray-drawer-icons/` before registering `self.indicator.set_icon_theme_path(str(ICON_DIR))`.
    - Fills `x=2..62, y=1..62` (`94%` of the canvas, ~2.5× larger in linear dimensions / >6× larger in area) with a stacked-window frame and a bold geometric vector count digit (`1`–`9`, `9+`) inside the window body.
  - **Silent Minimize (`follow = false`) & Window State Preservation**:
    - Disassembly of `/usr/bin/Hyprland` (`0xb816c0`, `tableOptBool(L, 1, "follow")`) proved `hl.dsp.window.move` takes `follow = false` (not `silent = true`) to invoke `movetoworkspacesilent`. Replaced the ignored `silent = true` + `toggle_special` flash workaround with `follow = false`, and preserved `pinned` and `fullscreen` states across minimize/restore cycles.
  - **Live Hyprland State Reconciliation, Event Sync & Drawer UX**:
    - Added `sync_with_hyprland()` to reconcile `self.minimized_windows` against `hyprctl clients -j` (`workspace.name == "special:minimized"`) at startup and before opening the drawer, plus `.socket2.sock` handlers for `movewindowv2>>`, `movewindow>>`, and `windowtitlev2>>` alongside `closewindow>>`.
    - **Window Switcher (`noctalia msg window-switcher`) Overlay Interception & Domino-Focus Fix**: When selecting a minimized window from Noctalia's window switcher (1-finger left-to-right edge swipe), Noctalia dispatches `hl.dsp.focus({window = "address:0x..."})`, which causes Hyprland to activate the entire `special:minimized` workspace as a persistent overlay over all workspaces. Furthermore, moving the selected window out of `special:minimized` *before* closing `special:minimized` causes Hyprland to automatically shift focus to the next remaining window in `special:minimized` and emit a cascading `activewindowv2>>` event for every minimized window. Fixed by: (1) synchronously latching a `650ms` `suppress_intercept_until` debounce in `_run_hypr_listener` on the first `activewindowv2>>` match, and (2) dispatching `hl.dsp.workspace.toggle_special("minimized")` **before** `hl.dsp.window.move(...)` in `build_restore_lua()` so `special:minimized` closes first and only the single selected window is restored to the current normal workspace.
    - Fixed the duplicate window title dictionary collision in `_interactive_drawer_worker()`, added origin workspace tags (`[class · WS N]`), added a `🧭  Restore All to Origin Workspaces` action alongside `📂  Restore All Here`, and made clicking the tray icon or pressing `SUPER + ALT + M` while the drawer is open toggle-close the launcher (`noctalia msg panel-close launcher`).
  - **`systemd --user` Supervision & Single-Instance Lock**:
    - Added an `fcntl.flock` lock (`$XDG_RUNTIME_DIR/hypr-tray-drawer.lock`) to `hypr-tray-drawer daemon`, created and enabled `core/.config/systemd/user/hypr-tray-drawer.service` (`~/.config/systemd/user/hypr-tray-drawer.service`), and updated `core/.config/hypr/config/autostart.lua` to start `systemctl --user start hypr-tray-drawer.service`.
  - Updated `references/config-paths.md`, `references/gotchas/wayland-noctalia.md` (Section 9), and `references/gotchas/hyprland.md` (Section 15).

## [2.64.0] - 2026-10-18
### Added & Fixed
- **Interactive Keybindings Cheatsheet Action Execution (`core/`, universal)**:
  - Updated `core/.local/bin/hypr-keybinds-menu` (`~/.local/bin/hypr-keybinds-menu`, launched via `SUPER + K`) so pressing `Enter` on any searched/selected keybinding executes its action immediately.
  - Prefixed submap-specific bindings (such as `[resize]`) in the `fzf` list and updated the header to `ENTER to run · ESC to exit`.
  - Implemented `trigger_bind_detached(dispatcher, arg)` to fork a detached background helper and immediately exit `hypr-keybinds-menu`, waiting until the floating `Keybindings` terminal window unmaps and focus returns to the previously active window before invoking `hyprctl eval "local fn = debug.getregistry()[<arg>]; if type(fn) == 'function' then fn() end"`.
  - Documented the Hyprland Lua registry keybind invocation pattern in `references/gotchas/hyprland.md` (Section 17).

## [2.63.0] - 2026-10-18
### Verification and Gotchas
- **Latest upstream VLC master retest (`vlcdots`, universal app-development knowledge; not deployed)**:
  - PR [#14](https://github.com/dsojevic/juxtopposed-vlc/pull/14) is merged. At the user's request, fetched upstream and created detached `/home/jmvp/work/juxtopposed-vlc-master-test` at `56834cb796aa8947f499f3f965fb3df1dad4f617`, with a separate `juxtopposed-vlc-master-test-build`. Qt/QuickTest 6.12.0, GCC 16.2.1, Meson 1.12.1; offscreen/software testing with isolated HOME/XDG directories.
  - Unmodified master fails Meson configuration with `medialibrary=disabled`: the new `test_src_misc_media_library_startup` registration requires the absent plugin. Applied only a temporary one-line `enabled: medialibrary_dep.found()` registration guard in the scratch checkout; no Qt production code or test assertion changes.
  - Final complete Qt run: **65 registrations, 63 OK / 2 FAIL**, including one shader-only backdrop skip under the software renderer. Failures: `test_breadcrumbsKeepHiddenAncestorsAvailable` at `tst_RedesignLibrary.qml:521` (`opened=false`) and `test_websiteNeedsAnExplicitClickAndAWebAddress` at `tst_RedesignAddons.qml:148`. Breadcrumb fails independently on both offscreen and minimal platforms, and offscreen without forcing the software backend. The customization-controls click test failed earlier grouped/isolated runs, then passed both consolidated runs without source changes; cause unconfirmed.
  - Resolved fresh test-only runtime omissions, not application regressions: built the static preparser, JSON preparser serializer, console logger, and modern `https` plugin in the new build. All four initially failing native interface/model tests then pass; subtitle scanner is **11 passed / 0 skipped** with its loopback HTTP fixture.
  - Evidence and unposted maintainer reply draft: `/tmp/opencode/vlc-master-retest-40h0oe3j/`. Installed alpha, private pin/patch/manifest, private main, and public `linux-installation` working branch remain unchanged. No package installation, deployment, player restart, visible GUI interaction, push, or PR reply. Added reusable cold-build prerequisites and configuration caveat to `gotchas/vlc.md`.

## [2.62.0] - 2026-10-18
### Added & Fixed
- **Surface Tablet Touch Keyboard & Bottom-Up Swipe Gesture on Lock Screen and Pre-Login Greeter (`profiles/surface`, device-specific)**:
  - **Root Cause of Invisible OSK on Post-Suspend Lock Screen (`ext-session-lock-v1`)**:
    - Disassembly of `/usr/bin/Hyprland` (`0.56.2`) (`Render::IHyprRenderer::renderLayer` and `Desktop::CViewHitTester::layerSurfaceAt`) revealed that while `CSessionLockManager::isSessionLocked()` is active (`noctalia msg session lock` via `ext-session-lock-v1`), Hyprland skips rendering **all** `zwlr_layer_shell_v1` layer surfaces (even `overlay` layer 3) if `m_aboveLock == 0` (the default), and blocks all touch hit-testing on layer surfaces unless `m_aboveLock == 2`.
    - When waking from suspend/hibernate with the Surface Book 3 base detached (`Oct 18 11:58:14`, `14:38:50`, `14:39:05`), `lisgd` detected the 1-finger bottom-up swipe and toggled `wvkbd-mobintl` via `SIGRTMIN`, but `wvkbd` opened invisibly behind the lock screen and could not receive touch input.
  - **Post-Suspend Lock Screen Fix (`above_lock = 2`)**:
    - Added `hl.layer_rule({ name = "surface-wvkbd-above-lock", match = { namespace = "^(wvkbd)$" }, above_lock = 2 })` to `profiles/surface/.config/hypr/config/profile/inputs.lua`, rendering `wvkbd-mobintl` above the Noctalia lock screen and enabling touch interaction while keeping keyboard focus on the password input (`keyboard_interactivity = none`).
  - **Cold-Boot `lisgd` Startup Segfault Fix (`-w 3000 -h 2000`)**:
    - Disassembly of `/usr/bin/lisgd` (`0x2155`–`0x2bd9`) showed that without `-w` and `-h`, `lisgd` calls `wl_display_connect(NULL)` when `$WAYLAND_DISPLAY` is set and dereferences the pointer unchecked (`wl_proxy_get_version(NULL)`), causing a `SIGSEGV` in `libwayland-client.so.0` if the Wayland socket is not yet ready.
    - Updated `profiles/surface/.local/bin/hypr-lisgd` to pass explicit `-w 3000 -h 2000` geometry to `lisgd`, bypassing `wl_display_connect()` completely.
  - **Cold-Boot Pre-Login `greetd` Tablet OSK & Gesture Support**:
    - Because `/usr/bin/noctalia-greeter-compositor` lacks `zwlr_layer_shell_v1` and `zwp_virtual_keyboard_v1`, created `profiles/surface/scripts/surface-greeter-session.sh` (`/usr/local/bin/surface-greeter-session`), `profiles/surface/scripts/surface-greeter-client.sh` (`/usr/local/bin/surface-greeter-client`), and `profiles/surface/scripts/surface-greeter-hyprland.lua` (`/etc/greetd/surface-hyprland.lua`), wired into `profiles/surface/setup.sh`.
    - Runs `noctalia-greeter` (`dev.noctalia.Greeter`) inside a minimal zero-gap/zero-border Hyprland compositor alongside `wvkbd-mobintl -L 320 -H 320 --hidden` and a `lisgd` supervisor for the 1-finger bottom-up swipe (`1,DU,B/BL/BR,*,R`), with automatic fail-safe fallback to `/usr/bin/noctalia-greeter-session` if Hyprland fails to initialize.
  - Updated `profiles/surface/gotchas/virtual-keyboard.md` (Sections 3E–3G).

## [2.61.0] - 2026-10-18
### Installed
- **VLCdots `0.1.0-alpha.1` (`vlcdots`, universal user-local app; explicitly approved)**:
  - Installed versioned native VLC4/Qt payload and bundled Python backend at `~/.local/opt/vlcdots-alpha/releases/0.1.0-alpha.1`, with relative `current` link, `~/.local/bin/vlcdots-alpha`, and validated `~/.local/share/applications/vlcdots-alpha.desktop` (**VLCdots Alpha**). The launcher creates its own persistent profile at original `$XDG_STATE_HOME/vlcdots-alpha/profile` (default `~/.local/state/vlcdots-alpha/profile`) on use. It does not migrate the development player's temporary settings.
  - Reused the validated build via fresh `meson install --no-rebuild --strip --destdir` staging, with no compiler or package installation. Native payload is about 67 MB; system dependencies remain required. Full installed inventory has 777 files/links. Original ani-cli history, normal VLC settings, MIME defaults, and all 120 fingerprinted mapped development files remain unchanged. No visible window, desktop control, restart of the user's player, or real provider request performed.
  - Added installer/runtime tools and documentation: immutable version directories, hashed ownership receipt, collision refusal, separate per-process VLC4 loader/plugin/data/libexec paths, and ownership-checked uninstall that preserves profiles/cache/history. Fixed an actual trial failure caused by protected same-UID systemd/PAM processes: unrelated identifiable opaque processes no longer block installation; possible opaque VLC/helpers still refuse, and known executable/library-map matches still block removal. Opaque custom hosts loading private libraries under unrelated names remain a documented best-effort limitation.

### Verification and Git
- Full Python/tooling suite **326/326 pass** with installed-CLI offline fixtures; portable run **326 tests, 16 opt-in skips**. Alpha coverage: **22 launcher + 31 installer** checks. Native/Qt result remains **44 pass / 1 unchanged breadcrumb failure**, all Anime tests passing; no new native source change for packaging.
- Verified relocated candidate and actual installed launcher: offscreen Qt with queue panel, synthetic playback to EOF, no QML errors, bundled bridge history import, unchanged fixture history, and immutable payload inventory after execution. Process mappings and the preparser executable resolve entirely inside the installed release, not the build/source tree. A separate clean scratch install tested real refusal to uninstall a mapped release, followed by successful uninstall preserving fake profile/normal VLC/cache/history. Menu entry passes `desktop-file-validate`.
- User approved private `main` promotion and publication. Committed alpha source/docs as `378245e`, followed by process-guard fix `81ae9d3`; fast-forwarded private main without checking out an older helper tree while the development player was live. Atomically pushed **main and annotated `v0.1.0-alpha.1`** to private `JValdivia23/vlcdots`. Remote main and peeled tag resolve to `81ae9d305ea75e050c16719f6fb15ec90e96f844`; private checkout is clean. No binaries, profiles, caches, or history committed. Public `juxtopposed-vlc` branch/PR remains untouched and clean.

## [2.60.0] - 2026-10-18
### Added & Fixed
- **Surface Hibernation CMOS `rtc0` Epoch Alignment (`profiles/surface`, device-specific)**:
  - **7-Cycle `suspend-then-hibernate` Verification**: Verified all 7 consecutive `suspend-then-hibernate` cycles since `[2.55.0]` (`Oct 15 22:04` through `Oct 17 19:24` $\rightarrow$ `Oct 18 11:58` on `7.2.9-2-cachyos`) transitioned cleanly at the 30-minute mark into zero-watt `HibernateMode=shutdown` with zero `ipts` freezer aborts.
  - **Root Cause of Hibernation Clock Freeze (`<7h`) / `-7h` Wake Offset (`>7h`)**: Disassembly of `vmlinux` (`timekeeping_suspend`, `timekeeping_resume`, `read_persistent_clock64`, `mach_get_cmos_time`, `sync_hw_clock`) and inspection of `/sys/class/rtc/rtc0`, `/sys/class/rtc/rtc1` (`acpi-tad` `_GRT` `-EIO`), and `/sys/firmware/efi/efivars/RTC-378d7b65-8da9-4773-b6e4-a47826a833e1` (`0x01a4 = 420 min = 7h`) proved that while Linux's 11-minute `sync_hw_clock` timer writes **UTC** to CMOS `rtc0` (`0x70`/`0x71`), Surface UEFI POST re-initializes `rtc0` from the SAM EC clock at **`UTC - 25,179s` (`~-7h`)** on every S5 hibernation wake. Because `timekeeping_resume()` computes $\Delta = \text{ts\_new} - \text{timekeeping\_suspend\_time} = T_{\text{hibernated}} - 25,179\text{s}$, any hibernation `<7h` produced $\Delta < 0$ (rejected by `timekeeping_resume()`, injecting `0s` and freezing both `CLOCK_REALTIME` and `CLOCK_BOOTTIME`), while any hibernation `>7h` injected $T_{\text{hibernated}} - 25,179\text{s}$ (waking 7 hours behind until `chronyd` stepped `CLOCK_REALTIME` after Wi-Fi reconnected).
  - **Option B Pre-Hibernate `rtc0` Epoch Alignment Hook**:
    - Created `/usr/local/bin/surface-hibernate-rtc-sync` (`profiles/surface/scripts/surface-hibernate-rtc-sync.sh`) and `/etc/systemd/system-sleep/19-surface-rtc-hibernate.sh` (`profiles/surface/systemd/19-surface-rtc-hibernate.sh`), symlinked in `/usr/lib/systemd/system-sleep/19-surface-rtc-hibernate.sh` and wired into `profiles/surface/setup.sh`.
    - During `pre/hibernate` (`SYSTEMD_SLEEP_ACTION=hibernate` or direct `hibernate`; no-op during `s2idle`), the helper latches `STA_UNSYNC` (`0x0040`) via `adjtimex()` to prevent `sync_hw_clock` from overwriting `rtc0` during snapshot page allocation, and shifts `rtc0` to `CLOCK_REALTIME + offset_sec` (`-25,179s` in `/var/lib/surface-hibernate-rtc/offset_sec`) via `ioctl(RTC_SET_TIME)`.
    - At `syscore_resume()`, `timekeeping_resume()` subtracts `timekeeping_suspend_time` ($t_{\text{sleep}} - 25,179\text{s}$) from POST-initialized `rtc0` ($t_{\text{wake}} - 25,179\text{s}$), natively injecting the exact $+T_{\text{hibernated}}$ into both `CLOCK_REALTIME` and `CLOCK_BOOTTIME` before userspace thaws.
    - During `post/hibernate`, the helper immediately restores `rtc0` to UTC (`CLOCK_REALTIME`), clears `STA_UNSYNC`, and records the POST sample in `/var/lib/surface-hibernate-rtc/last_wake_sample.json` for bounded (`-25200 ± 300s`) drift auto-calibration on the next NTP-synchronized cycle.
  - **Snapshot Memory Preallocation & IPTS Transition Polish**:
    - Updated `/usr/local/bin/surface-hibernate-compressor` (`profiles/surface/scripts/surface-hibernate-compressor.sh`) to set and verify `/sys/power/image_size = 4800000000` alongside `lz4` at boot, allowing `hibernate_preallocate_memory()` to bypass `shrink_all_memory()` (`zram0` swap thrashing) whenever saveable RAM is $\le$ `max_size` ($\approx 3.93\text{ GB}$).
    - Updated `/etc/systemd/system-sleep/21-surface-ipts-resume.sh` (`pre/*`) to cleanly stop active `iptsd@*.service` instances and `reset-failed` stale units before sleep/hibernation entry, eliminating the 3s `stop-sigterm` `SIGKILL` timeout and stale `iptsd@dev-hidraw6.service` restore failure.
    - Added a `0.5s` fast-path healthy check (`is_device_healthy()`) to `/usr/local/bin/surface-ipts-resume-recover` (`profiles/surface/scripts/surface-ipts-resume-recover.sh`), reducing healthy resume verification from `3.10s` to `1.09s` while preserving the full `6 × 2s` recovery loop if needed.
  - **Live `suspend-then-hibernate` Cycle Verification (`Oct 18 12:52` $\rightarrow$ `14:34`)**:
    - Across a `30m` `s2idle` + `1h 11m 36s` (`<7h`) S5 hibernation cycle, `19-surface-rtc-hibernate.sh` shifted `rtc0` by `-25,179s` at `13:22:36`, allowing `timekeeping_resume()` to natively inject **`+4,295.8s`** into both `CLOCK_REALTIME` and `CLOCK_BOOTTIME` at wake (`14:34:12`) instead of freezing at `0s`; `rtc0` was immediately restored to UTC and `last_wake_sample.json` captured for `-25180s` auto-calibration.
    - Snapshot memory preallocation (`image_size = 4.80 GB`) allocated **`979,012` pages (`3.92 GB`, +27% more RAM) in `5.56s` (`704.32 MB/s`)**, cutting preallocation time in half (`11.96–12.60s` $\rightarrow$ `5.56s`).
    - Zero `iptsd` `SIGKILL` timeouts, zero failed units (`systemctl --failed` = `0`), and `surface-ipts-resume.service` completed its healthy check on `iptsd@dev-hidraw6.service` **`0.89s`** after `user.slice` thaw.
  - Documented in [`profiles/surface/gotchas/sleep-hibernate.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/sleep-hibernate.md) (Section 12).

## [2.59.0] - 2026-10-17
### Added
- **Private Anime episode transport and browser (`vlcdots`, universal app development; not deployed)**:
  - Added an **Episodes** tab alongside Queue, Bookmarks, and real in-file Chapters. It shows the playing series' in-memory catalog and actual current episode, with Refresh, keyboard selection, loading/error states, and virtualized rows. Fractional entries remain visible but unsupported for playback.
  - Redesigned full/mini-player Previous/Next use the same verified catalog order, including gaps and explicit boundaries, while ordinary media keeps its queue controls. No EOF auto-advance, global hotkey/media-key interception, watched-state claims, or persisted episode lists.
  - Reused ani-cli's existing pinned metadata hook and exact resolver; catalog lookup makes only search + episode-list requests. Original title, Sub/Dub, and quality are captured from the playing request rather than sidebar selection. Held input-item identities restore known queued anime contexts and invalidate stale requests on media changes.
  - Review corrected navigation-only cache argv, same-series/owned-input cancellation, transport-origin error routing through final playback validation, and busy keyboard activation. Original history, count-cache format, and normal resolver contract remain unchanged.
  - Reused `/home/jmvp/work/vlcdots-counts-build` incrementally after confirming the user's player was closed; previous `/home/jmvp/work/vlcdots-build` and public Linux contribution remain untouched. No commits, pushes, deployment, package/system changes, desktop input/captures, or real provider requests.

### Verification
- Final Python/tooling **273/273 pass** with installed-CLI offline checks enabled (portable run: 16 opt-in skips); installed-CLI compatibility **18/18**. Final full Qt suite **44 pass / 1 unchanged baseline breadcrumb failure**. All Anime checks pass: panel/Episodes **41/41**, protocol **20/20**, native bridge/lifecycle **36/36**, plus redesigned player view **59/59**. Incorrect synthetic helper imports/correlation fixtures were corrected without weakening production validation or assertions.
- Real playlist checks verify the resolver-to-current-item hand-off, a single prefetch for gapped `1 → 3 → 5`, direct selection preserving Dub/720p, ordinary-media clearing, queued-anime restoration, and boundary no-ops. Refused loopback streams exercise identity/queue behavior, not decoding. Restoring a failing queued stream without stopping first let normal VLC error auto-advance invalidate the fixture; it now stops and selects without restart. GDB traced a separate test-only post-Totals crash to KF6 WindowSystem's Qt child surviving libvlc's module unload. Proper outer RAII core ownership now outlives QCoreApplication; no QObject detachment, leaked core, skipped assertion, or production workaround remains.
- Incremental player compilation and final actual-launcher offscreen Qt/synthetic-playback smoke pass with the play-queue panel instantiated, no QML errors, unchanged fixture history, and temporary-profile cleanup. Live provider playback and visible UI remain user-tested only. Final managed patch: **18 Qt files, 269387 bytes**, SHA256 `41f43c0d79882498179db6bff16ca675ce44df737f1adce1ed723afdad6f16d3`; detached HEAD remains `cebf0a2`, and exact staged-patch verification passes. All builds/tests have finished; the isolated build is ready for manual launch, not deployment.

## [2.58.0] - 2026-10-16
### Added
- **Private Anime episode counters (`vlcdots`, universal app development; not deployed)**:
  - History rows display `Ep 3/12` from ani-cli's available episode list, `Ep 3/?` while unknown, or `Ep 3.5 · 13 eps` for specials/nonsequential numbering. These are last-opened episodes, not completion or planned-season totals.
  - Added lazy, bounded visible-row lookups and a persistent app-owned count cache (default `~/.cache/vlcdots/episode-totals.json`, original XDG cache base captured before profile isolation). Cache data contains provider IDs/counts/source fingerprint/fetch time, never titles, stream URLs, or watch positions. Six-hour freshness is checked on history Reload.
  - Metadata capture uses a SHA-guarded temporary copy hook of installed ani-cli 5.1.5, exiting before playback after its own parsed episode list. Full provider-ID verification is required; the installed file and original history remain untouched. No new metadata provider or vendored scraper/script.
  - Fixed cache integration/lifecycle regressions found during review: explicit PATH resolution before source reads, real-entrypoint cache-roundtrip coverage, source-change/future-timestamp invalidation, dropping stale native totals on Reload, and retrying cancelled lookups when the panel reopens. Metadata updates preserve selection, manual episode edits, audio, quality, and media.
  - Kept the user's live `/home/jmvp/work/vlcdots-build` untouched; the new counter build is `/home/jmvp/work/vlcdots-counts-build` with a configured-only `/home/jmvp/work/vlcdots-counts-prefix`. Public Linux contribution and pinned source revision remain unchanged; no commits, pushes, deployment, package/system changes, desktop control, or live provider requests.

### Verification
- Python/tooling **247/247 pass** with installed-CLI offline checks enabled (portable run: 13 opt-in skips), including the actual bridge entrypoint proving search + episode-list only on a miss and no requests on a subsequent cache hit. Full counter-build Qt suite: **44 pass / 1 existing breadcrumb failure**, with Anime panel **29/29**, protocol **15/15**, and native bridge/lifecycle **18/18**. A new counts-error presentation failure was corrected in production code (generic retry notice), leaving its assertion intact. The recorded breadcrumb assertion remains unchanged and failing.
- Full counter-player compilation and final actual-launcher offscreen Qt/synthetic-playback smoke pass; the cache flag is accepted, fixture history is unchanged, and the temporary profile is cleaned. No visible new-build UI, real audio, live provider count lookup, or live stream was exercised. Final managed patch: 15 Qt files, 159904 bytes, SHA256 `11a5027c181a2550a5d8b5cd73b7a40869f101a5182aa44ae328715fd3999682`; detached source HEAD stays `cebf0a2`. All builds/tests have finished; manual launch is available when the user is ready.

## [2.57.1] - 2026-10-16
### Verified
- **Live private VLC Anime UI (`agents`, universal app testing; no deployment/config change)**:
  - Tested the user's already-running isolated Wayland player using window-targeted Hyprland keyboard events and VLC-only `grim -T` captures. No restart, package installation, new playback request, provider lookup, or playback-cancellation test performed.
  - Passed live checks: populated history, row selection updating the episode, Reload restoring an edited episode from the import, blank input disabling Play, letter input rejection, valid integer input re-enabling Play, Sub/Dub selection, quality selection, `Ctrl+Shift+L` hide/show, Back to library, and Anime reopening with medialibrary disabled.
  - Restored original selections. Before/after image regions for the loaded media title, playback-time display, and play/pause control match exactly. Original ani-cli history bytes/size/mtime are unchanged. VLC remains running; all temporary window captures were deleted. No watch titles or media images added to Git.

### Gotchas
- History-row buttons and Reload activate with **Space**, but **Enter/Return** did not activate them in this build; the sidebar has explicit Enter handlers and does respond. Recorded as a keyboard-consistency issue, not fixed during the test-only task. See [`references/gotchas/vlc.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/vlc.md).
- On the current Lua Hyprland API, use `hl.dsp.focus({ window = ... })`, not `hl.dsp.window.focus`. Read back the active PID/address before sending input; an IPC `ok` alone is not proof of focus. The client's `stableId` worked as the window-only `grim -T` identifier.

## [2.57.0] - 2026-10-16
### Added
- **Private ani-cli integration development (`vlcdots`, universal app development; not deployed)**:
  - Adopted tested fork revision `cebf0a2868290f99f348f74d9abc60ae426e8bdf` in the private source lock. `linux_validated: true` records the earlier build/headless/Wayland smoke only, not an all-green Qt suite; the known breadcrumb failure remains recorded and unresolved.
  - Private work is on `feature/ani-cli-integration`, with native source changes in detached `/home/jmvp/work/vlcdots-player` and a separate `/home/jmvp/work/vlcdots-build`. The public Linux PR branch remains untouched. No commits, pushes, package changes, deployment, desktop launchers, or dotfiles consumer added in this integration session.
  - Captured 15 native Qt source/test files in private `vlcdots/patches/0001-ani-cli-integration.patch`. Only the dedicated source worktree index carries those changes; `player.py prepare` verifies its full index tree equals pinned HEAD plus that patch. Public `linux-installation` stays clean, and detached HEAD is unchanged.
  - Implemented a bounded, read-only ani-cli history parser and a sandboxed resolver adapter using the installed CLI rather than a copied scraper. Imported episodes mean last opened, not completed or seconds-resumable. Sub/Dub and quality are request selectors, not saved language preferences.
  - Final private Python/tooling verification: 156/156 tests pass with the installed-CLI offline checks enabled (default portable run: 7 opt-in skips). The ani-cli 5.1.5 compatibility suite passes 8/8 offline checks, including the fractional-episode bug reproduction and refusal guard. Full player build succeeds; the full private Qt suite is 44 passed / 1 failed (only the recorded breadcrumb failure). All three new Anime test registrations pass: 20 panel, 10 protocol, and 10 native bridge/lifecycle checks. The actual launcher's capability probe, offscreen Qt startup, 4-second synthetic FFV1 playback, and temporary-profile cleanup pass; fixture history bytes/mtime stay unchanged. No visible window, real audio, resolver-to-playlist playback, or live provider streams tested. Regular VLC settings and existing ani-cli history remain unchanged.

### Development Gotchas
- ani-cli can replace a custom menu with rofi/dmenu when stdin is not a terminal. The resolver uses PTY stdin, capture-only player/menu helpers, a temporary `ANI_CLI_HIST_DIR`, and an ID/episode check before accepting a stream. Native cancellation must send TERM and allow cleanup before force-killing the Python bridge; immediate KILL can orphan its CLI process group. See [`references/gotchas/vlc.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/vlc.md).
- Review identified that ani-cli 5.1.5 treats decimal episode dots as regular-expression wildcards, so sandbox history does not by itself prove fractional episode identity. Fractional imports must remain lossless, but playback must fail closed until safe exact membership verification exists.
- Built-player capability checks are required: this Meson build compiles out DBus single-instance controls and Qt update checks, so unconditionally passing their negative switches prevents startup. The launcher now queries isolated `--ignore-config --longhelp`, accepts only three fixed allowlisted option names, refuses failed/incomplete probes, and omits unsupported switches. No dependencies or global settings were changed to work around this.

## [2.56.0] - 2026-10-16
### Added
- **Juxtopposed VLC Universal Dev Setup Baseline (`agents`, universal scope — NOT a hardware profile)**:
  - Local projects: public fork `/home/jmvp/work/juxtopposed-vlc` (`https://github.com/JValdivia23/juxtopposed-vlc`, upstream `dsojevic/juxtopposed-vlc`, branch `linux-installation` starts at `097cbdb516452914faffcce719291cf14e2f3760`); private repo `/home/jmvp/work/vlcdots` (`https://github.com/JValdivia23/vlcdots`, still scaffold only — 21 tests PASS, personal Anime NOT implemented, dotfiles consumer NOT yet wired).
  - User-approved installs completed exit 0: `nasm 3.02-1.1` + `qt6-wayland 6.12.0-1.1`, plus followup `extra/vulkan-headers 1:1.4.363.0-1` (confirmed via `pacman -Q`; universal dev dependency, no GPU driver changes) after the first compile stopped at step 1481/2341 on missing `vulkan/vulkan.h`. No VLC binary installed, no live VLC config changed, system `libvlc 3.0.24` untouched. Deps NOT added to `core/packages.txt` (declared in external project eventual integration; no deployment hook yet).
  - Juxtopposed fork is native Qt/QML VLC4-dev, not a skin/config overlay for VLC3; current release assets are Windows beta only. Requires isolated binary/plugins plus XDG config+data+cache. `TOP_BUILDDIR` launcher is `build/bin/vlc-static`; normal `bin/vlc` targets the installed prefix. No global plugin path / `LD_LIBRARY_PATH` changes made.
  - Out-of-tree build `/home/jmvp/work/juxtopposed-vlc-build` configured with Meson>=1.10, `--prefix=/home/jmvp/.local/opt/juxtopposed-vlc`, `debugoptimized`, `wrap-mode=nofallback`, Qt enabled, medialibrary disabled, tests auto. Full `nice 10` ninja `-j2` Linux VLC4 Qt/QML build SUCCEEDED after headers; `build/bin/vlc-static --version` exit 0 (VLC4-dev `1f3b575`, GCC 16.2.1). Prefix still NOT deployed: live `/home/jmvp/.local/opt/juxtopposed-vlc` remains absent; validation used only a `--destdir` stage copy at `/tmp/opencode/vlc-runtime-stage-78nj7tnx`.
  - Documented universal gotchas in [`references/gotchas/vlc.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/vlc.md).

### Fixed
- **Juxtopposed Meson Configure Failure With Disabled MediaLibrary (source fix in dev fork, not a system patch)**:
  - Before patch, configure failed at `test/meson.build:55` because optional ML was disabled yet `test_modules_misc_media_tracks` still hard-depended on the absent plugin.
  - Minimal fix adds `enabled: medialibrary_dep.found()` to the `media_tracks` + `medialibrary` test entries in `test/modules/meson.build`. Same configure after patch succeeds (800 build targets).
- **Juxtopposed Qt Test Registration Fix (by other coding agent, source fix in dev fork)**:
  - First suite run: 42 tests, 40 pass / 2 fail. Fixed `test_qt_subtitle_timeline_scanner` registration in `modules/gui/qt/meson.build`: adds per-test `VLC_PLUGIN_PATH=build/modules`, `module_depends` on `filesystem` + `http` plus original `subtitle`/`subsdec`.
  - After reconfigure: targeted subtitle test PASS, full suite FINAL 41 passed / 1 failed. Remaining failure is the unchanged QML test `tst_RedesignLibrary/test_breadcrumbs` (`KeepHiddenAncestorsAvailable`, line 426, `opened == false`); reproduces on sequential runs with fresh XDG dirs. Cause unconfirmed — do NOT call it flaky/env-only, do NOT skip it or change UI (out of scope).

### Notes / Limitations
- Missing external `medialibrary>=0.13` means the initial baseline has reduced library functionality, not full beta parity.
- Eventual anime resume requires own state: `ani-cli` history records only the last launched episode and `--continue` advances to next, with no seconds-precision position.
- Keep watch history/tokens/cache out of both git repos (runtime local state only).
- **Validation results (all isolated, no live install)**:
  - 2s synthetic FFV1+PCM clip headless-decoded through EOF exit 0 in build tree and stage copy. Does NOT test real PipeWire/speaker output.
  - `meson install --no-rebuild --destdir /tmp/opencode/vlc-runtime-stage-78nj7tnx/stage` SUCCEEDED. Installed `bin` needs `libvlc.so.12`/`libvlccore.so.9` with no RPATH (`readelf`): raw stage `--version` fails 127; per-process `LD_LIBRARY_PATH=<stage>/lib:<stage>/lib/vlc` succeeds for version + playback — never exported globally. Five Qt plugins `ldd`: no missing.
  - User-approved 8s silent native GUI test: staged player launched with `QT_QPA_PLATFORM=wayland` and private XDG dirs, exit 0. Hyprland IPC: own window, class `vlc`, `xwayland:false`, `mapped:true`; logs show `qt_wayland`, `avcodec`, `egl_wl`, EOF. Native Wayland display + playback validated; screenshot NOT used (IPC/log evidence only), sources in `/tmp/opencode/vlc-native-wayland-e_2r2og7`. No hw-decode/HDR/real-audio claims.
- Public fork `linux-installation` branch changes are Linux guide + Meson test-setup fixes, no production UI changes. Upstream DRAFT PR is OPEN: `https://github.com/dsojevic/juxtopposed-vlc/pull/14` ('Document Linux builds and fix optional-dependency test setup'); public `linux-installation` HEAD `cebf0a2`. No git commit/push/PR from this task; no live VLC settings modified; system `libvlc3` untouched; no core package changes or service reloads.

## [2.55.0] - 2026-10-15
### Fixed
- **Surface `suspend-then-hibernate` 30-Minute Transition Failure on CachyOS 7.x (`profiles/surface`)**:
  - Diagnosed and resolved root cause where 30-minute RTC wakes from `s2idle` to `hibernate` aborted after `20.002s` (`Freezing user space processes failed ... task:iptsd-check-dev state:D`) and fell back into indefinite `s2idle` suspend.
  - Patched [`profiles/surface/dkms/ipts/src/eds2.c`](file:///home/jmvp/dotfiles/profiles/surface/dkms/ipts/src/eds2.c): reduced `GET_FEATURES_TIMEOUT` from `30 * MSEC_PER_SEC` to `5 * MSEC_PER_SEC` (matching `linux-surface`) and replaced uninterruptible `mutex_lock` + `wait_for_completion_timeout` (`state:D`) with `mutex_lock_interruptible` + `wait_for_completion_interruptible_timeout` (`state:S`), allowing the kernel process freezer and `timeout` signals to interrupt an in-flight `GET_FEATURES` ioctl in `<1ms` when the touch panel is powered off (lid closed).
  - Patched [`profiles/surface/dkms/ipts/src/control.c`](file:///home/jmvp/dotfiles/profiles/surface/dkms/ipts/src/control.c): fixed upstream typo overwriting `cmd.tail_offset_addr_lower` instead of setting `cmd.tail_offset_addr_upper`.
  - Rebuilt and reloaded `ipts/2024.04.16` via DKMS for `7.2.9-2-cachyos` and `6.18.55-2-cachyos-lts`.
- **Sleep & Hibernation Subsystem Consistency Hardening (`profiles/surface`)**:
  - **Reactivated `surface-hibernate-compressor.service` on CachyOS Kernels**: Removed `ConditionKernelVersion=*-surface` from [`surface-hibernate-compressor.service`](file:///home/jmvp/dotfiles/profiles/surface/systemd/surface-hibernate-compressor.service) and the `*-surface` kernel-name filter from [`surface-hibernate-compressor.sh`](file:///home/jmvp/dotfiles/profiles/surface/scripts/surface-hibernate-compressor.sh) while preserving the `Surface*` DMI hardware check and `/proc/crypto` `lz4` self-test guard. Restored active `lz4` RAM-image compression on `7.2.9-2-cachyos`.
  - **Guarded `surface-unplug-lid-handler` Against Active Sleep Transitions**: Added `is_sleep_in_progress()` check in [`surface-unplug-lid-handler.sh`](file:///home/jmvp/dotfiles/profiles/surface/scripts/surface-unplug-lid-handler.sh) so `ADP1` uevents emitted during the 30-minute RTC wake do not call `systemctl suspend-then-hibernate` while `systemd-suspend-then-hibernate.service` is already active.
  - **Registered Battery Sleep Hook & Guarded Clamshell IPTS Hook**: Symlinked `/usr/lib/systemd/system-sleep/20-surface-battery-resume.sh` $\rightarrow$ `/etc/systemd/system-sleep/20-surface-battery-resume.sh`, updated [`21-surface-ipts-resume.sh`](file:///home/jmvp/dotfiles/profiles/surface/systemd/21-surface-ipts-resume.sh) to skip starting `surface-ipts-resume.service` on `post/*` when the lid is physically closed, and added `SuccessExitStatus=143 SIGTERM` to [`surface-ipts-resume.service`](file:///home/jmvp/dotfiles/profiles/surface/systemd/surface-ipts-resume.service).
  - **Self-Healing `hypr-lisgd` Evdev FD Monitor**: Updated [`hypr-lisgd`](file:///home/jmvp/dotfiles/profiles/surface/.local/bin/hypr-lisgd) to monitor `/proc/$LISGD_PID/fd/*` every 2 seconds and automatically restart `lisgd` if `libinput` drops the `/dev/input/event*` descriptor across suspend/resume or `iptsd` restarts.
  - Synced `/etc/udev/rules.d/71-iptsd-touchscreen-uaccess.rules` and [`profiles/surface/setup.sh`](file:///home/jmvp/dotfiles/profiles/surface/setup.sh).

## [2.54.0] - 2026-10-13
### Added
- **Surface Touch Daemon Resilience via `systemd --user` Services (`profiles/surface`)**:
  - Migrated [`hypr-lisgd`](file:///home/jmvp/dotfiles/profiles/surface/.local/bin/hypr-lisgd) and [`hypr-touch-resizer`](file:///home/jmvp/dotfiles/profiles/surface/.local/bin/hypr-touch-resizer) from ephemeral subshell/agent background jobs into permanent `systemd --user` units:
    - [`hypr-lisgd.service`](file:///home/jmvp/dotfiles/profiles/surface/.config/systemd/user/hypr-lisgd.service): Supervises `lisgd` touchscreen gesture daemon, attaching to IPTS virtual touchscreen (`/dev/input/event25`).
    - [`hypr-touch-resizer.service`](file:///home/jmvp/dotfiles/profiles/surface/.config/systemd/user/hypr-touch-resizer.service): Supervises interactive window resizer daemon with `--foreground`.
    - Both units configured with `PartOf=graphical-session.target`, `After=graphical-session.target`, `WantedBy=graphical-session.target`, `Restart=always`, and `RestartSec=2s`.
  - Updated [`profiles/surface/.config/hypr/config/profile/autostart.lua`](file:///home/jmvp/dotfiles/profiles/surface/.config/hypr/config/profile/autostart.lua) to trigger `systemctl --user start hypr-lisgd hypr-touch-resizer`.
  - Verified automatic self-healing restart upon process kill/crash and active event socket listening for `submap>>resize`.

## [2.53.0] - 2026-10-13
### Added
- **Unified Minimized Window Tray Drawer (`core`)**:
  - Developed and deployed [`hypr-tray-drawer`](file:///home/jmvp/dotfiles/core/.local/bin/hypr-tray-drawer) in core dotfiles:
    - Provides a single, clean StatusNotifierItem (SNI) tray icon for Noctalia to manage minimized application windows, avoiding system bar clutter.
    - **Dynamic Visibility**: Stays completely hidden (`PASSIVE`) when 0 windows are minimized. When apps are minimized, automatically becomes `ACTIVE`, displaying the `window-restore-symbolic` icon and a numeric count badge.
    - **Single-Click Tray Activation**: Left-clicking the tray icon triggers the `"activate"` StatusNotifierItem D-Bus signal to instantly open Noctalia's native interactive launcher drawer (`noctalia dmenu`), displaying each minimized app with its icon and title, plus "Restore All" and "Close All" quick actions.
    - **Context Menu & Secondary Activation**: Right-clicking opens the native GTK/DBusMenu dropdown, and middle-clicking activates "Restore Most Recent".
    - **Hyprland Socket2 Sync**: Background thread listens to Hyprland's `.socket2.sock` for `closewindow>>` events to auto-prune windows if closed in the background.
    - **Special Workspace Overlay Fix**: Atomically toggle off `special:minimized` upon moving the window so Hyprland does not display the special workspace as a full-screen overlay over the monitor.
  - **Keybindings (`binds.lua`)**:
    - `SUPER + M`: Minimize active window to the tray drawer (`hypr-tray-drawer minimize`).
    - `SUPER + SHIFT + M`: Restore the most recently minimized window back to active workspace (`hypr-tray-drawer restore`).
    - `SUPER + ALT + M`: Open the interactive minimized apps drawer menu directly via keyboard (`hypr-tray-drawer menu`).
  - **Focus-or-Launch Integration (`helpers.lua`)**:
    - Enhanced `helpers.launch_or_focus` to automatically detect if a target app is currently minimized in `special:minimized`, seamlessly pulling it onto the active workspace and focusing it upon launcher activation.
  - **Autostart (`autostart.lua`)**:
    - Added `hypr-tray-drawer daemon` to core Hyprland autostart.

## [2.52.0] - 2026-10-13
### Added
- **Interactive Touchscreen Window Resizer Daemon (`profiles/surface`)**:
  - Developed and deployed [`hypr-touch-resizer`](file:///home/jmvp/dotfiles/profiles/surface/.local/bin/hypr-touch-resizer) daemon for Microsoft Surface Book 3:
    - Listens to Hyprland's UNIX event socket (`.socket2.sock`) for `submap>>resize`.
    - Claims an exclusive `EVIOCGRAB` on the IPTS virtual touchscreen device (`/dev/input/event25`) whenever `SUPER + R` resize mode is active. This prevents Wayland applications from receiving touch inputs or text selections.
    - Translates 1-finger touchscreen drags into real-time relative window resizing (`resizeactive`) via Hyprland's IPC socket (`.socket.sock`), enabling true 1:1 touchscreen dragging across active window surfaces.
    - Quick tap (<350ms, <40px displacement) immediately confirms and exits resize mode cleanly.
    - 30-second inactivity safeguard auto-exits resize mode if left idle.
    - Double-fork daemonized with single-instance lock file (`/run/user/$UID/hypr-touch-resizer.pid`).
    - Configured auto-start in [`profiles/surface/.config/hypr/config/profile/autostart.lua`](file:///home/jmvp/dotfiles/profiles/surface/.config/hypr/config/profile/autostart.lua).
- **Universal Window Resizing & Touch Gestures (`core` & `profiles/surface`)**:
  - Unified keyboard resizing in [`binds.lua`](file:///home/jmvp/dotfiles/core/.config/hypr/config/binds.lua): replaced layout-dependent `splitratio` with Hyprland's native `resizeactive` dispatcher (40px deltas), providing smooth, continuous resizing across all windows whether tiled or floating.
  - Added both `SUPER + R` and `SUPER + r` enter bindings and modifier hold-through (`modmask: 64`) for arrows and Vim HJKL keys.
  - Corrected mouse drag bindings to `{ mouse = true }` across all mouse drag bindings.
  - Deployed dedicated helper script [`hypr-resize-step`](file:///home/jmvp/dotfiles/profiles/surface/.local/bin/hypr-resize-step) and connected it to 2-finger horizontal swipe gestures in [`hypr-lisgd`](file:///home/jmvp/dotfiles/profiles/surface/.local/bin/hypr-lisgd):
    - **2 fingers swipe right**: Expands active window width by 60px.
    - **2 fingers swipe left**: Shrinks active window width by 60px.
  - Expanded `extend_border_grab_area` from 10 to 24 pixels in [`decorations.lua`](file:///home/jmvp/dotfiles/core/.config/hypr/config/decorations.lua) (~5mm touch target on high-DPI Surface displays).

## [2.51.0] - 2026-10-13
### Fixed
- **Surface IPTS Wake Handshake & Gesture Auto-Reconnect (`profiles/surface`)**:
  - Hardened `/usr/local/bin/surface-ipts-resume-recover` against wake race conditions after suspend/hibernation.
  - Increased `iptsd-check-device` timeout from `2s` to `6s` (`timeout --kill-after=2s 6s`) to prevent prematurely SIGKILLing in-flight Intel MEI firmware handshakes (which previously led to 30-second kernel blocks: `GET_FEATURES timed out!`).
  - Added a 2-second initial wake settle delay and expanded retry attempts from 4 to 6 (spaced by 2s).
  - Integrated `pkill -x lisgd` upon successful recovery so the `hypr-lisgd` supervisor automatically re-attaches to newly enumerated virtual touchscreen evdev nodes.
  - Documented complete architecture and failure mode in [`profiles/surface/gotchas/touchscreen-iptsd.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/touchscreen-iptsd.md).

## [2.50.0] - 2026-10-13
### Added
- **Surface Book 3 Hybrid Audio Architecture with EBU R128 AutoGain Leveling (`profiles/surface`)**:
  - Upgraded [`surface-book-hybrid.json`](file:///home/jmvp/dotfiles/profiles/surface/.local/share/easyeffects/output/surface-book-hybrid.json) into a 7-stage unified DSP audio stack, combining Surface Book 3 acoustic chassis correction, JackHack96 Dolby Atmos 3D room impulse, and automatic volume leveling.
  - **Dynamic Range Normalization (AutoGain)**: Integrated EBU R128 / ITU-R BS.1770 AutoGain normalizer (`target: -14.0 LUFS`) that automatically eliminates wide volume swings, smoothly lifting quiet whispers/dialogue while preventing loud action scenes and music from blasting.
  - **DSP Efficiency & CPU Optimization**: Pruned 32-band EQ to 11 active acoustic bands (eliminating 21 idle 0 dB biquad filters and 4M+ floating-point ops/sec) and disabled 4x oversampling on the limiter to native lookahead rate, reducing limiter cycle time by 91% (from 620 µs down to 54 µs).
  - Persisted the complete JackHack96 spatial Impulse Response library (25+ `.irs` files) into `profiles/surface/.local/share/easyeffects/irs/`.
  - Set `surface-book-hybrid` as the persistent default in `~/.config/easyeffects/db/easyeffectsrc`.

## [2.49.0] - 2026-10-13
### Fixed
- **Hybrid Keyboard & Tiled Submap Resizing (`core`)**:
  - Resolved issue where keyboard Arrow keys and Vim HJKL keys did not resize tiled windows in Hyprland's `dwindle` layout after entering `SUPER + R` resize mode.
  - Implemented dynamic window state inspection via `hl.get_active_window().floating`: tiled windows now dynamically adjust container split boundaries via native `hl.dsp.layout("splitratio <ratio>")` (`+0.05` / `-0.05`), while floating windows use `resizeactive` (`30px` deltas).
  - Added support for modifier hold-through (`modmask = 64`): registered `SUPER + Arrow` and `SUPER + HJKL` keybinds alongside bare keys so resizing functions reliably whether `SUPER` is released or kept held.
  - Registered full touchscreen and mouse drag bindings (`mouse:272` and `mouse:273`, both bare and `SUPER`-held) across active window surfaces.
  - Added split reset binding via `=` / `SUPER + =` (`splitratio 1.0 exact`) to quickly re-center split containers to 50/50.
  - Documented root cause and solution in [`references/gotchas/hyprland.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/hyprland.md) and [`references/keybindings.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/keybindings.md).

## [2.48.0] - 2026-10-13
### Added
- **Interactive Window Resize Mode Submap (`core`)**:
  - Implemented `SUPER + R` interactive resize mode submap in universal [`core/.config/hypr/config/binds.lua`](file:///home/jmvp/dotfiles/core/.config/hypr/config/binds.lua) using Hyprland's native Lua `hl.define_submap("resize", ...)`.
  - Enables effortless touchscreen and mouse left-drag resizing (`mouse:272`) anywhere on active windows without requiring millimeter precision on thin 1px window borders.
  - Enabled keyboard incremental resizing with repeating keys via Arrow keys and Vim HJKL keys (30px step increments).
  - Configured clean exit bindings via `Escape`, `Return`, or `SUPER + R`, returning to default submap seamlessly.
  - Added OSD feedback notification on entering resize mode.
  - Updated universal keyboard shortcut documentation in [`references/keybindings.md`](file:///home/jmvp/.agents/skills/system-personalization/references/keybindings.md).

## [2.47.0] - 2026-10-13
### Added
- **Surface Book 3 Psychoacoustic Audio DSP & EasyEffects Engine (`profiles/surface`)**:
  - Engineered and deployed a tailored 5-stage DSP audio enhancement preset [`surface-book.json`](file:///home/jmvp/dotfiles/profiles/surface/.config/easyeffects/output/surface-book.json) for the Microsoft Surface Book 3 tablet speakers.
  - **Psychoacoustic Virtual Bass**: Integrated Calf Bass Enhancer generating 2nd and 3rd order harmonics for frequencies up to 145 Hz (+10 dB virtual bass presence), leveraging the "missing fundamental" effect so the human brain perceives deep sub-bass despite physical speaker driver limits.
  - **Subsonic High-Pass Protection**: Configured a 90 Hz steep 12 dB/oct cut (RLC BT) filter to eliminate destructive sub-bass excursion, preventing speaker distortion, rattling, and voice coil overheating.
  - **Chassis Acoustic Equalization**: Configured a 32-band parametric EQ providing lower-mid body warmth (156–194 Hz), speech clarity (1.3–1.7 kHz), chassis resonance peak suppression (-3 dB at 3.2 kHz), and air/sparkle (9.5–12 kHz).
  - **Stereo Widening & Peak Limiting**: Applied Calf Stereo Tools (+15% width, 0.04 ms delay) for immersive soundstage and LSP True Peak Limiter (-1.0 dB ceiling) to guarantee distortion-free playback at maximum volume.
  - Installed plugin engines `lsp-plugins-lv2` and `calf`, tracking them in [`profiles/surface/packages.txt`](file:///home/jmvp/dotfiles/profiles/surface/packages.txt).
  - Configured silent background service autostart (`easyeffects --service-mode`) in [`autostart.lua`](file:///home/jmvp/dotfiles/profiles/surface/.config/hypr/config/profile/autostart.lua).
  - Documented complete architecture, plugin engine dependencies, EasyEffects 8.3 preset paths, and A/B testing commands in [`profiles/surface/gotchas/audio-dsp.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/audio-dsp.md).

## [2.46.0] - 2026-10-13
### Added
- **Surface Touch & Stylus (IPTS) Support for Linux 7.2 Mainline / CachyOS (`profiles/surface`)**:
  - Enabled complete Surface touchscreen and stylus functionality on stock `linux-cachyos` (7.2.9+) without requiring `linux-surface` kernel patching.
  - Vendored IPTS kernel driver source from upstream `intel-precise-touch` (commit `3b88a45`) into `profiles/surface/dkms/ipts/` and deployed to `/usr/src/ipts-2024.04.16/`.
  - Configured DKMS integration with `BUILD_EXCLUSIVE_KERNEL="-cachyos"` and an LLVM/Clang-aware Makefile wrapper that automatically handles CachyOS Clang-built kernel flags. Successfully built and installed modules for `7.2.9-2-cachyos` and `6.18.55-2-cachyos-lts`.
  - Created runtime PCI MEI binder script [`surface-ipts-mei-bind.sh`](file:///home/jmvp/dotfiles/profiles/surface/scripts/surface-ipts-mei-bind.sh) (installed to `/usr/local/bin/surface-ipts-mei-bind`) dynamically binding device `8086:34e4` (Ice Lake iTouch MEI function) to `mei_me` using config index 9 (`MEI_ME_PCH12_CFG`).
  - Added udev rules [`72-surface-ipts-mei-bind.rules`](file:///home/jmvp/dotfiles/profiles/surface/systemd/72-surface-ipts-mei-bind.rules) (installed to `/etc/udev/rules.d/72-surface-ipts-mei-bind.rules`) triggering binding on PCI add and `mei_me` module loading. Fully backwards-compatible and acts as a no-op on `linux-surface`.
  - Updated Limine bootloader configuration in `/etc/default/limine` (`BOOT_ORDER="linux-cachyos, linux-surface*, *, *lts, *fallback, Snapshots"`) making `linux-cachyos` the default boot entry while preserving `linux-surface` as an immediate working fallback.
  - Updated `profiles/surface/setup.sh` (step 10) and `profiles/surface/packages.txt` to guarantee 100% turnkey deployment on fresh installations.
  - Documented complete architecture, root causes, gotchas, and verification commands in [`profiles/surface/gotchas/kernel-cachyos-ipts.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/kernel-cachyos-ipts.md) and symlinked to active skill references.

### Changed
- **Full System Upgrade**:
  - Upgraded 171 packages via `pacman -Syu`, including `linux-cachyos` (7.2.9-1 -> 7.2.9-2), `linux-cachyos-lts` (6.18.55-1 -> 6.18.55-2), `limine` (12.9.0-1 -> 12.9.3-2), `limine-snapper-sync`, and core desktop applications (`zen-browser-bin`, `neovim`).
  - Installed `dkms` package to automate out-of-tree module builds across future kernel updates.

### Fixed
- **Surface Touchscreen Gestures (`lisgd`) Boot Race Condition & Auto-Recovery**:
  - Resolved startup crash where `lisgd` dumped core with `SEGV` (`wl_proxy_get_version`) when spawned before Hyprland had initialized the Wayland display socket.
  - Wrapped `hl.exec_cmd("~/.local/bin/hypr-lisgd")` inside `hl.on("hyprland.start", ...)` in [`autostart.lua`](file:///home/jmvp/dotfiles/profiles/surface/.config/hypr/config/profile/autostart.lua).
  - Enhanced [`hypr-lisgd`](file:///home/jmvp/dotfiles/profiles/surface/.local/bin/hypr-lisgd) with polling loops for Wayland socket readiness and dynamic device node access.
  - Added a supervisor loop so `lisgd` automatically reconnects to `/dev/input/event*` if `iptsd` reloads, sleeps, or re-enumerates devices after wake.

## [2.45.0] - 2026-10-10
### Added
- **Touch ID Fingerprint Login Integration (`greetd` / Noctalia Greeter)**:
  - Configured [`/etc/pam.d/greetd`](file:///etc/pam.d/greetd) with `auth sufficient pam_fprintd.so` placed immediately after `pam_nologin.so`.
  - Enables biometric login using the MacBook Pro's Apple T2 Touch ID sensor at the Noctalia / greetd login screen, logging in user `java1127` upon resting an enrolled finger on the sensor.
  - Automatically falls back to standard password entry if fingerprint verification times out or is bypassed.
  - Automated deployment in [`profiles/macbook-t2/setup.sh`](file:///home/java1127/dotfiles/profiles/macbook-t2/setup.sh) and updated hardware documentation in [`apple-t2.md`](file:///home/java1127/dotfiles/profiles/macbook-t2/gotchas/apple-t2.md).
- **ani-cli-mx Spanish Anime & Media Streaming Integration (`core`)**:
  - Installed terminal streaming helper [`ani-cli-mx`](file:///usr/bin/ani-cli-mx) (v3.0.10-1) from the AUR via `yay`.
  - Scrapes Spanish-language anime, movies, series, and doramas using providers like AnimeAV1, JKAnime, and PelisPlusHD with automatic fallback mirrors.
  - Added `ani-cli-mx` to universal package specification [`core/packages.txt`](file:///home/jmvp/dotfiles/core/packages.txt) in alphabetical order to preserve reproducibility across all systems.

## [2.44.0] - 2026-10-09
### Fixed
- **rEFInd Duplicate Arch Entry Resolution**:
  - Diagnosed duplicate Arch Linux boot icons in rEFInd boot menu from `refind.log`. Discovered that rEFInd was scanning both the factory Apple 300MB EFI partition (`nvme0n1p1`, labeled `EFI`) and CachyOS's 4GB boot partition (`nvme0n1p3`, mounted as `/boot`), finding `EFI/limine/limine_x64.efi` on both.
  - Added `dont_scan_volumes "EFI"` to `/boot/EFI/refind/refind.conf` to ignore the factory ESP.
  - Added `dont_scan_dirs "EFI/BOOT"` to suppress the generic fallback boot loader entry (`BOOTX64.EFI`).
  - Deduplicated repeated `default_selection "limine,vmlinuz,cachyos"` lines in `refind.conf`.
  - Updated [`profiles/macbook-t2/setup.sh`](file:///home/java1127/dotfiles/profiles/macbook-t2/setup.sh) to automatically enforce `dont_scan_volumes "EFI"` and `dont_scan_dirs "EFI/BOOT"` on fresh installations.
  - Result: Clean 2-entry boot menu with exactly 1 Arch Linux entry (Limine) and 1 macOS entry.

## [2.43.0] - 2026-10-09
### Added
- **Turnkey Dual-GPU & Hardware Automation in Dotfiles (`profiles/macbook-t2/setup.sh`)**:
  - Integrated complete automated deployment for Intel UHD 630 iGPU booting, Apple GMUX display routing, and AMD dGPU power-off into `profiles/macbook-t2/setup.sh`.
  - Added privileged helpers [`t2-dgpu-control-helper`](file:///usr/local/libexec/t2-dgpu-control-helper) and `t2-dgpu-control-status` directly into the dotfiles repository under `profiles/macbook-t2/scripts/`.
  - Tracked and automated systemd units: [`kait2en-dgpu-off.service`](file:///etc/systemd/system/kait2en-dgpu-off.service), [`kait2en-dgpu-suspend.service`](file:///etc/systemd/system/kait2en-dgpu-suspend.service), [`suspend-fix-t2.service`](file:///etc/systemd/system/suspend-fix-t2.service), and [`t2-cpu-control.service`](file:///etc/systemd/system/t2-cpu-control.service).
  - Added dedicated initramfs drop-in configuration [`20-apple-igpu.conf`](file:///etc/mkinitcpio.conf.d/20-apple-igpu.conf) (`MODULES+=(i915?)`) ensuring the Intel graphics driver is reliably built into early boot images even if CachyOS hardware detection configs are regenerated.
  - Automated bootloader configuration in `setup.sh`: adds `i915.enable_guc=3` to `/etc/default/limine` and configures `spoof_osx_version 10.9` in `/boot/EFI/refind/refind.conf` while removing any invalid EFI drivers that could freeze the boot process.
  - Guarantees 100% turnkey restoration of all GPU power savings, display scaling, thermals (~52°C), and sleep/resume stability upon executing `./install.sh` on a fresh OS installation.

## [2.42.0] - 2026-10-09
### Added
- **ani-cli & paru Universal Package Integration (`core`)**:
  - Installed CachyOS native AUR helper [`paru`](file:///usr/bin/paru) (v2.1.0-3) to facilitate managing AUR packages cleanly.
  - Installed anime streaming CLI [`ani-cli`](file:///usr/bin/ani-cli) (v5.1-1) from the AUR, which leverages native `mpv`, `ffmpeg`, and `fzf` playback pipelines.
  - Added `ani-cli` and `paru` to universal core package specification [`core/packages.txt`](file:///home/java1127/dotfiles/core/packages.txt) in alphabetical order to preserve reproducibility across all systems.

## [2.41.0] - 2026-10-09
### Fixed & Resolved
- **Apple T2 Dual-GPU Unhide & Integrated Graphics Boot (Intel UHD 630)**:
  - Discovered and resolved the root cause of the missing iGPU: Apple EFI firmware deliberately cuts power to and hides `00:02.0` unless `apple-set-os` is invoked.
  - Configured native Apple OS spoofing via rEFInd (`spoof_osx_version 10.9`), which triggers `APPLE_SET_OS_PROTOCOL` (`Mac OS X 10.9` / `Apple Inc.`) during early boot to expose the Intel UHD 630.
  - Eliminated the `gpu-power-prefs=01 00 00 00` NVRAM black-screen hazard by keeping NVRAM as `00 00 00 00` (discrete POST) and delegating display multiplexing cleanly to Linux `apple-gmux` (`force_igd=y`).
  - Added `i915?` to initramfs (`/etc/mkinitcpio.conf.d/11-chwd.conf`) and `i915.enable_guc=3` to `/etc/default/limine`.
  - Configured and verified [`kait2en-dgpu-off.service`](file:///etc/systemd/system/kait2en-dgpu-off.service) with an asynchronous loop: powers off the discrete AMD GPU via `vgaswitcheroo` (`DIS: :Off`), saving ~12W at idle and dropping thermals to ~52°C.
  - Verified live: OpenGL rendering directly on `Mesa Intel(R) UHD Graphics 630 (CFL GT2)` with AMD card completely sleeping.

## [2.40.0] - 2026-10-09
### Added
- **KAIT2EN T2 GPU Control & Integrated GPU Boot (`t2-dgpu-control`)**:
  - Compiled from source and deployed KAIT2EN's [`t2-dgpu-control`](file:///usr/local/bin/t2-dgpu-control) (GTK4 / Libadwaita), privileged helpers [`t2-dgpu-control-helper`](file:///usr/local/libexec/t2-dgpu-control-helper) and `t2-dgpu-control-status`, desktop entry, and Polkit policies.
  - Installed and enabled [`kait2en-dgpu-off.service`](file:///etc/systemd/system/kait2en-dgpu-off.service) to automatically shut down the discrete AMD GPU via `vgaswitcheroo` after boot, saving ~12W at idle.
  - Installed and enabled [`kait2en-dgpu-suspend.service`](file:///etc/systemd/system/kait2en-dgpu-suspend.service) which cycles dGPU power during system sleep/resume to eliminate black-screen wake crashes.
  - Configured Apple GMUX NVRAM EFI variable (`gpu-power-prefs`) to `01 00 00 00` (Integrated boot).
  - Updated [`environment.lua`](file:///home/java1127/dotfiles/profiles/macbook-t2/.config/hypr/config/profile/environment.lua) with dynamic PCI vendor detection so VA-API uses `iHD` when in iGPU mode and `radeonsi` when in dGPU mode.
- **Battery Turbo Boost Toggle & Status Telemetry (`amdgpu-power-switch`)**:
  - Enhanced [`amdgpu-power-switch.sh`](file:///home/java1127/dotfiles/profiles/macbook-t2/scripts/amdgpu-power-switch.sh) and symlinked to `~/.local/bin/amdgpu-power-switch`.
  - Added commands: `status` (live telemetry), `turbo-toggle` (toggles Intel Turbo Boost on battery with desktop notification), `turbo-on`, `turbo-off`, and `game` (3D performance mode).
  - Added persistent override `/etc/default/t2-battery-turbo` allowing user to maintain burst performance on battery.

## [2.39.0] - 2026-10-09
### Added
- **Apple T2 Touch ID Integration (`t2-touchid`)**:
  - Built and deployed [`t2-touchid`](file:///usr/local/bin/t2-touchid) daemon connecting to the Apple T2 Secure Enclave Processor (SEP) over the internal CDC-NCM virtual link (`t2_ncm`) using Apple's BridgeXPC protocol.
  - Configured NetworkManager link-local IPv6 profile `/etc/NetworkManager/system-connections/t2-ncm.nmconnection`.
  - Integrated with `fprintd` via virtual storage socket drop-in `/etc/systemd/system/fprintd.service.d/kait2en-t2-touchid.conf` and enabled [`kait2en-t2-touchid.service`](file:///etc/systemd/system/kait2en-t2-touchid.service).
  - Integrated D-Bus `org.kait2en.TouchId` with [`kait2en-touchbar`](file:///usr/local/bin/kait2en-touchbar) to render live touch-to-unlock prompts on the Touch Bar during authentication.
  - Wired into `/etc/pam.d/sudo` and `/etc/pam.d/hyprlock` via `auth sufficient pam_fprintd.so` with seamless password fallback and <kbd>Esc</kbd> instant cancel.
  - Verified live: SEP unlocked via macOS, automatically detected macOS UID 502 with 3 fingers (`right-thumb`, `right-middle-finger`, `right-index-finger`), and successfully authenticated `sudo` via Touch ID.
- **CPU Package C-State & PCIe Power Tuning (`t2-power-tune` & `t2-power-explorer`)**:
  - Deployed [`t2-power-tune`](file:///usr/local/bin/t2-power-tune) (GTK4 / Libadwaita) with real-time 1s interval Package C-state telemetry (C2 through C10) sampled from `/sys/kernel/debug/pmc_core/package_cstate_show`.
  - Configured granular PCIe ASPM controls (L0s, L1) and runtime power management auto-sleep for idle buses.
  - Installed compiled Rust release binary [`t2-power-explorer`](file:///usr/local/bin/t2-power-explorer) for live PCIe power state capability and display lane diagnostics on pure Wayland.
  - Installed Polkit actions `/usr/share/polkit-1/actions/org.t2powertune.policy` and `/usr/share/polkit-1/actions/org.t2powerexplorer.policy`.

## [2.38.0] - 2026-10-09
### Changed
- **Display Scaling & Text Legibility Calibration (`macbook-t2` Profile)**:
  - Updated [`profiles/macbook-t2/.config/hypr/config/profile/monitors.lua`](file:///home/java1127/dotfiles/profiles/macbook-t2/.config/hypr/config/profile/monitors.lua) internal display scale (`eDP-1`) from `1.33` to `1.6` ($1800 \times 1125$ logical resolution).
  - Aligns the MacBook Pro 15,1 Retina screen with the upstream `9.0pt` baseline terminal font size without altering global `core/` configurations or affecting the Surface Book 3 (`2.0x` scale).
  - Restored comfortable, crisp text rendering and balanced workspace real estate.
- **Hyprland Lua Dynamic Monitor Scaling Fix (`hypr-monitor-scale`)**:
  - Patched [`core/.local/bin/hypr-monitor-scale`](file:///home/java1127/dotfiles/core/.local/bin/hypr-monitor-scale) to evaluate monitor changes via `hyprctl eval "hl.monitor(...)"` with fallback to `hyprctl keyword`.
  - Fixes runtime scale cycling (`SUPER + /` and `SUPER + ALT + /`) on modular Lua Hyprland where legacy `keyword` is rejected.
  - Linked missing upstream scripts into `~/.local/bin/` (`hypr-autoscale`, `hypr-text-size`, `hypr-monitor-scale`, etc.).
- **Documentation & Gotchas**:
  - Documented Lua `hl.monitor` runtime API requirements in `references/gotchas/hyprland.md` (Section 12).

## [2.37.0] - 2026-10-09
### Added
- **Next-Gen Touch Bar Daemon (`kait2en-touchbar`)**:
  - Replaced legacy static SVG daemon [`tiny-dfr`](file:///usr/bin/tiny-dfr) with [`kait2en-touchbar`](file:///usr/local/bin/kait2en-touchbar) compiled from source.
  - Patched `renderer.rs` with Arch Linux Adwaita and Cantarell font paths (`/usr/share/fonts/Adwaita/AdwaitaSans-Regular.ttf`).
  - Configured Arch-native udev seat permissions in [`/etc/udev/rules.d/99-zz-kait2en-touchbar.rules`](file:///etc/udev/rules.d/99-zz-kait2en-touchbar.rules) granting desktop `video` group access to `/dev/dri/card0`, digitizer, backlight, and uinput.
  - Features enabled: dark-first OLED display, 2-finger volume swipe on dark bar, 3-finger brightness swipe on dark bar, 2-finger carousel swipe across 3 layers (Media keys, F1–F12, and extended Mac navigation keys Home/End/PgUp/PgDn/Ins/Del).
  - Integrated with [`t2-sleep-helper`](file:///usr/local/bin/t2-sleep-helper) for clean pre-suspend shutdown and post-resume reload.
- **T2 CPU Control Utility & Service (`t2-cpu-control`)**:
  - Installed `msr-tools` (`1.3-4`) from Arch repositories for CPU MSR read/write support (`rdmsr`/`wrmsr`).
  - Deployed KAIT2EN's GTK4 / Libadwaita utility [`t2-cpu-control`](file:///usr/local/bin/t2-cpu-control) with polkit integration and background systemd service [`t2-cpu-control.service`](file:///etc/systemd/system/t2-cpu-control.service).
  - Provides visual and persistent tuning for Intel Core i9 PL1 sustained power limits, PL2 short burst limits, and thermal ceilings to eliminate PROCHOT throttling.

### Changed
- **AMDGPU Dynamic DPM Power Optimization (`POWER_SAVING` Mode 2)**:
  - Discovered that on AC power, AMD Radeon Pro 560X defaulted to `3D_FULL_SCREEN` mode 1, locking core/memory clocks at 1000 MHz and consuming 15.26 W idle at 67°C.
  - Updated [`profiles/macbook-t2/scripts/amdgpu-power-switch.sh`](file:///home/java1127/dotfiles/profiles/macbook-t2/scripts/amdgpu-power-switch.sh) and `/usr/local/bin/amdgpu-power-switch.sh` to enforce `manual` DPM with profile 2 (`POWER_SAVING`) during AC mode while keeping CPU Turbo Boost enabled.
  - Immediate verification: Idle wattage dropped ~38% (from 15.26 W to 9.5–12 W), `sclk` dropped to 241–309 MHz, `mclk` dropped to 300 MHz, and GPU temperatures steadily cooled.
  - Updated [`profiles/macbook-t2/scripts/t2-sleep-helper`](file:///home/java1127/dotfiles/profiles/macbook-t2/scripts/t2-sleep-helper) and `/usr/local/bin/t2-sleep-helper` to automatically reapply GPU and CPU power policies on post-resume.

## [2.36.0] - 2026-10-09
### Changed
- **Full System Upgrade & Linux 7.2.9 T2 BCE Kernel Verification (`7.2.9-1-cachyos`)**:
  - **Upstream Regression Resolution**: Verified that CachyOS restored the Apple T2 staging drivers (`t2bce_vhci`, `t2bce_core`, `t2bce_dma`, `t2bce_audio`) and Apple SMC / Touch Bar modules (`appletbdrm`, `hid-appletb-bl`, `hid-appletb-kbd`, `applesmc-t2`) in kernel `7.2.9-1`.
  - **Pacman Unpinning**: Safely commented out `IgnorePkg = linux-cachyos linux-cachyos-headers` in `/etc/pacman.conf`.
  - **Full Package Upgrade (359 packages)**:
    - Upgraded core kernel stack: `linux-cachyos` `7.2.9-1`, `linux-cachyos-headers` `7.2.9-1`, `linux-cachyos-lts` `6.18.55-1`.
    - Upgraded desktop compositor & shell: `hyprland` `0.56.2-4.1`, `noctalia` `5.2.1-1.1`, `noctalia-greeter` `1.6.0-1`, `hyprtoolkit` `0.6.0-1.1`.
    - Upgraded system core & init: `systemd` `262-1`, `mkinitcpio` `42.2-1`, `glibc` `2.44+r50`.
    - Upgraded audio & graphics: `pipewire` `1.6.9-1`, `wireplumber` `0.5.18-1.1`, `mesa` `3:26.2.4-1`.
    - Upgraded applications: `zen-browser-bin` `1.23.1b-1`, `firefox` `157.0.1-1.1`, `kitty` `0.49.2-1.1`, `dolphin` `26.08.2-1.1`, `lazygit` `0.66.0-1.1`, `swayimg` `5.6-2.1`.
  - **Diagnostics & Health**: Zero Hyprland config errors reported (`hyprctl configerrors`). `t2bce` modules verified installed in `/usr/lib/modules/7.2.9-1-cachyos/kernel/drivers/staging/t2bce/`.

## [2.35.0] - 2026-09-15
### Added
- **Custom CachyOS Live & Install ISO for Microsoft Surface Book 3 (`~/surface-iso-build/`)**:
  - Built custom bootable CachyOS ISO (`cachyos-desktop-linux-260915.iso`, 2.8 GB) tailored for Surface Book 3 (Intel Core i5/i7 10th Gen Ice Lake, `x86-64-v3`).
  - Integrated `linux-surface` 6.19.8 kernel, `linux-surface-headers`, `iptsd` (IPTS touchscreen/stylus daemon), `surface-control`, and `surface-dtx-daemon` (clipboard detachment).
  - Configured live bootloaders (`grub`, `systemd-boot`, `syslinux`) and `mkinitcpio` (`linux-surface.preset`) to boot directly into `vmlinuz-linux-surface` with enabled touchscreen and detachment daemons.
  - Automated Calamares installer for instant whole-disk installation:
    - Pre-selects **Erase disk** with **Btrfs** root filesystem.
    - Sets UEFI System Partition (ESP) to **4096 MiB (4 GiB)** matching CachyOS official recommendations for Limine/systemd-boot.
    - Enables **Swap (with Hibernate)** automatically (`initialSwapChoice: suspend` and `userSwapChoices: [none, suspend]`), creating a swap partition sized for RAM hibernation and configuring mkinitcpio `resume` hook and bootloader resume UUID parameter.
    - Injects `[linux-surface]` repository into target `/etc/pacman.conf` and imports Maximilian Luz's signing key (`56C464BAAC421453`) so updates work seamlessly via `pacman -Syu`.
- **Surface Dotfiles Profile Pre-Install Repository Fix (`profiles/surface/pre-install.sh`)**:
  - Corrected official Surface Linux repository server URL from outdated `pkg.surfacelinux.org` to active `pkg.surfacelinux.com`.

## [Unreleased]
### Added
- **Libinput Synthetic Gesture Daemon (`lisgd`) deployed for Surface Book 3 touchscreen (`surface`, 2026-10-09)**:
  - Installed `lisgd` from AUR (`aur/lisgd`) and tracked in [`profiles/surface/packages.txt`](file:///home/jmvp/dotfiles/profiles/surface/packages.txt).
  - Deployed udev session access rule [`profiles/surface/systemd/71-iptsd-touchscreen-uaccess.rules`](file:///home/jmvp/dotfiles/profiles/surface/systemd/71-iptsd-touchscreen-uaccess.rules) to `/etc/udev/rules.d/71-iptsd-touchscreen-uaccess.rules` with `TAG+="uaccess", RUN{builtin}+="uaccess"` (automated via step 9 in `profiles/surface/setup.sh`). Verified user POSIX ACL (`user:jmvp:rw-`) on `/dev/input/event*` (`IPTSD Virtual Touchscreen`) without granting insecure access to physical keyboard nodes.
  - Created dynamic launcher script [`profiles/surface/.local/bin/hypr-lisgd`](file:///home/jmvp/dotfiles/profiles/surface/.local/bin/hypr-lisgd) (symlinked to `~/.local/bin/hypr-lisgd`):
    - Dynamically detects the live IPTSD virtual touchscreen device node from `/proc/bus/input/devices`.
    - Calibrated with `-s 3.5` (175px edge grab area to clear top Noctalia bar), `-r 20` (20-degree non-overlapping gesture cones), `-t 80` (lowered distance threshold), `-m 1500` (1.5s timeout window).
    - Mapped edge gestures: bottom edge up for [`wvkbd`](file:///home/jmvp/.local/bin/hypr-virtual-keyboard), right edge left for Noctalia Control Center, left edge right for Noctalia Window Switcher, top edge down (and 2-finger swipe down) for fullscreen (`hl.dispatch(hl.dsp.window.fullscreen())`).
    - Mapped 3-finger in-screen gestures: horizontal swipe for workspace switching (`hl.dispatch(hl.dsp.focus({ workspace = "e+1" }))` / `"e-1"`), swipe down to close active window (`hl.dispatch(hl.dsp.window.close())`), swipe up to toggle floating (`hl.dispatch(hl.dsp.window.float({ action = "toggle" }))`).
    - Fixed Hyprland Lua IPC gotcha: `hyprctl eval 'hl.dsp.window.fullscreen()'` returns the closure object without dispatching; actions must be wrapped in `hl.dispatch(...)`.
  - Added profile autostart hook [`profiles/surface/.config/hypr/config/profile/autostart.lua`](file:///home/jmvp/dotfiles/profiles/surface/.config/hypr/config/profile/autostart.lua) (symlinked to `~/.config/hypr/config/profile/autostart.lua`).
  - Verified daemon running under PID 75047 with 0 errors, completely decoupled from Hyprland's internal key resolver.
- **Hyprgrass touch plugin evaluation, Spacebar collision discovery & rollback (`surface`, 2026-10-09)**:
  - Installed `hyprpm` (`0.56.2-4.1` from CachyOS) and built `hyprgrass` (v0.8.2) for touchscreen testing.
  - **Identified Critical Gotcha**: `hyprgrass` injects dummy `SKeybind` structs into Hyprland's `KeybindManager`. In Hyprland 0.56+, the new `Resolver` key lookup table matches empty keysym entries against physical keypresses, completely swallowing the physical **Spacebar** (`XKB_KEY_space`).
  - **Immediate Rollback**: Unloaded `hyprgrass` (`hyprctl plugin unload`), killed `wvkbd-mobintl`, restored clean `inputs.lua` and `autostart.lua`, and reloaded Hyprland (`hyprctl reload`). Space key functionality was immediately restored and verified.
  - Documented root cause and architecture in [`profiles/surface/gotchas/touchscreen-hyprgrass.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/touchscreen-hyprgrass.md) and linked in `SKILL.md`.

### Fixed
- **Surface IPTS recovery gaps corrected; touchscreen and automatic dispatch verified (`surface`, 2026-10-08)**:
  - Confirmed the original resume hook emitted `change`, while packaged iptsd rules require `add`; an already-active device also does not retrigger `SYSTEMD_WANTS` when its daemon is stopped.
  - Added Surface-only `scripts/surface-ipts-resume-recover.sh` and `systemd/surface-ipts-resume.service`, updated the dispatcher and profile deployment. Recovery now retains the one-second hardware delay in an asynchronous, bounded worker, rediscovers the current IPTS touchscreen, sends a targeted `add`, and explicitly starts only an inactive matching daemon. Healthy daemons, vendor bindings, and the existing 3-second stop guard are preserved; unfinished recovery is stopped before another sleep transition.
  - Guarded deployment and unit verification passed. The live manual worker restored the stopped `iptsd@dev-hidraw6.service` (PID `35009`), kernel/Hyprland registered both virtual inputs, and **the user confirmed touch works**. Cleared only the stale failure whose old node was absent. Seven mocked recovery/dispatcher scenarios passed; registered-hook dispatch was subsequently verified below, while physical pen remains untested.
  - Original-hook backup: `/var/backups/surface-ipts-resume-20261008-161227-34891/`. Compressor remains LZO; sleep and boot config hashes were unchanged. No driver reload, package install, suspend, or reboot was initiated during deployment. Evidence: `~/.cache/opencode/surface-standby-tests/ipts-recovery-z4wvl2hs/`; documented in `profiles/surface/gotchas/touchscreen-iptsd.md` and `sleep-hibernate.md`, section 9.
  - **First direct-cycle validation found incomplete registration**: Original session/collector restored; normal udev started `iptsd@dev-hidraw0.service` (PID `36795`) and user confirmed touch works and the menu is hidden. The new worker did not run: dispatchers under `/etc/systemd/system-sleep` are ignored by this installed systemd, which scans only `/usr/lib/systemd/system-sleep`. Registered/read-back verified an IPTS-only symlink and updated safe/idempotent profile deployment; ten registration mock scenarios passed. Existing recovery, boot, sleep, and battery-hook file hashes were unchanged. One retest prompt was cancelled before any sleep request; the subsequent confirmed retry passed below. The battery-resume hook has the same unregistered-path issue and was only documented, not modified. `chronyd` stepped the clock `+230.951801s`; no wake-speed or battery-power claim is supported. Evidence: `ipts-recovery-z4wvl2hs/direct-hibernate-x9pc08ys/` and `registered-hook-retest-gt6ybkeh/`.
  - **Registered-hook direct restore passed**: Journal confirms automatic worker start/finish and healthy-instance preservation for `iptsd@dev-hidraw6.service` (PID `37942`). User confirmed full power-off, lid-only restoration of the original desktop, and working touch; both virtual inputs remained present, with no failed system units or Hyprland config errors. The worker finished ~2.13s after `user.slice` thaw, so its waits were asynchronous. No new race was deliberately induced; pen, overnight behavior, and exact wake speed remain unmeasured. Clock correction still occurred later (`+88.570899s`); no clock/compression/sleep/boot tuning was applied. Evidence: `ipts-recovery-z4wvl2hs/registered-hook-retry-pinr1140/`.
- **Surface Limine boot-menu delay reduced (`surface`, 2026-10-08)**:
  - User observed a visible 5-second kernel-selection countdown during hibernation restoration and approved a **hidden 1-second menu** instead of zero-second autoboot.
  - Confirmed active Limine 12.9.0, selected `CachyOS.linux-surface`, and `/boot/limine.conf`. Changed only `timeout: 5` → `timeout: 1` and added global `quiet: yes`; Surface default, remember-last behavior, regular/LTS kernels, all snapshot entries, kernel arguments, theme settings, and EFI binaries were preserved.
  - Verified backup: `/var/backups/limine-fast-resume-20261008-153612-33670/limine.conf`. Guarded against concurrent config/binary changes, installed the reviewed staged edit under the boot lock, and verified exact read-back; no bootloader reinstallation, firmware-order change, package install, or reboot performed.
  - Expected saving: approximately **4 seconds** on subsequent normal boots and hibernation restores; the user subsequently confirmed the menu is hidden, but exact timing/speedup remains unmeasured. Press Space during the remaining second to reveal the recovery menu. Documented this Surface-only preference, rollback caveats, and evidence in `profiles/surface/gotchas/sleep-hibernate.md`, section 8; capture under `~/.cache/opencode/surface-standby-tests/limine-fast-resume-booaiyec/`.
- **Surface Book dual-battery watchdog `start-limit-hit` recovery (`surface`, 2026-10-08)**:
  - **Issue**: `systemctl --failed` reported `surface-battery-watchdog.service` failed after reboot with `start-limit-hit`.
  - **Root Cause**: During boot and active AC charging, the kernel fires rapid `power_supply` udev `change` events for `BAT2`. Udev rule `99-surface-battery.rules` requested `surface-battery-watchdog.service` more than 5 times within 10 seconds, exceeding systemd's default unit start limit burst. While the script itself safely rate-limits restarts to 30s, systemd marked the unit as failed.
  - **Fix**: Added `StartLimitIntervalSec=0` to `[Unit]` in [`profiles/surface/systemd/surface-battery-watchdog.service`](file:///home/jmvp/dotfiles/profiles/surface/systemd/surface-battery-watchdog.service) (keeping the profile-specific configuration isolated in `profiles/surface/`). Documented in [`profiles/surface/gotchas/battery-upower.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/battery-upower.md).
- **Surface Book AC disconnect clamshell battery drain fix & 30-min hibernation (`surface`, 2026-10-06)**:
  - **Issue**: When the laptop was suspended with the lid closed while plugged in, unplugging the charger left the laptop trapped in indefinite `s2idle` Modern Standby or woke it to userspace without ever transitioning to zero-watt hibernation, draining the battery completely in backpacks or overnight.
  - **Root Cause**: `HandleLidSwitchExternalPower=suspend` in `/etc/systemd/logind.conf.d/10-lid-sleep.conf` invoked plain `systemd-suspend.service` on AC. When unplugged, `systemd-logind` never re-evaluates lid policies without physical lid motion. Disconnecting the charger woke the SoC (`ADP1` wakeup), and because `button.lid_init_state=open` signaled `open` upon wake, the laptop sat awake with screen off for 15 minutes before `hypridle` suspended it again.
  - **Fix**:
    1. Set `HandleLidSwitchExternalPower=suspend-then-hibernate` in [`profiles/surface/systemd/10-lid-sleep.conf`](file:///home/jmvp/dotfiles/profiles/surface/systemd/10-lid-sleep.conf) and deployed to `/etc/systemd/logind.conf.d/10-lid-sleep.conf`. Configured `HibernateOnACPower=yes` in `10-suspend-then-hibernate.conf` so it consistently hibernates after 30 minutes on both AC power and battery.
    2. Tuned `HibernateDelaySec=30min` and `SuspendEstimationSec=30min` in [`profiles/surface/systemd/10-suspend-then-hibernate.conf`](file:///home/jmvp/dotfiles/profiles/surface/systemd/10-suspend-then-hibernate.conf) and deployed to `/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf`.
    3. Created AC disconnect clamshell handler [`profiles/surface/scripts/surface-unplug-lid-handler.sh`](file:///home/jmvp/dotfiles/profiles/surface/scripts/surface-unplug-lid-handler.sh) (deployed to `/usr/local/bin/surface-unplug-lid-handler`), systemd unit [`profiles/surface/systemd/surface-unplug-lid.service`](file:///home/jmvp/dotfiles/profiles/surface/systemd/surface-unplug-lid.service), and udev rule [`profiles/surface/systemd/98-surface-unplug-lid.rules`](file:///home/jmvp/dotfiles/profiles/surface/systemd/98-surface-unplug-lid.rules) (deployed to `/etc/udev/rules.d/98-surface-unplug-lid.rules`). When `ADP1` switches to `online=0`, the handler verifies if the lid is closed, debounces 1.5s, and triggers `systemctl suspend-then-hibernate`.
    4. Updated [`profiles/surface/setup.sh`](file:///home/jmvp/dotfiles/profiles/surface/setup.sh) to automate deployment.
  - **Verification**: Verified deployment to `/etc/systemd/`, `/etc/udev/rules.d/`, and `/usr/local/bin/`; `systemd-analyze verify` clean (0 errors); 0 `hyprctl configerrors`. Documented Section 4 in `profiles/surface/gotchas/sleep-hibernate.md`.
- **Surface Book spurious ACPI lid wake abort & 30s wake loop fix (`surface`, 2026-09-27)**:
  - **Issue**: Machine woke from `s2idle` after 90 minutes to enter hibernate, but aborted after 14 seconds and remained stranded awake with the lid closed overnight. When `button.lid_init_state=ignore` was initially tested, hibernation succeeded, but upon resuming from hibernation, the machine was trapped in an endless 30-second suspend loop.
  - **Root Cause**: Two colliding issues:
    1. With `button.lid_init_state=method` (kernel default), `acpi_button_resume()` called `acpi_lid_update_state()`, querying `_LID`. Due to async SAM EC initialization during wake, ACPI returned `1` (`open`), calling `acpi_pm_wakeup_event()` and tripping `pm_wakeup_pending()`, aborting the hibernation snapshot.
    2. With `button.lid_init_state=ignore`, the kernel suppressed initial lid state reporting entirely on resume. Because the lid was closed when entering sleep, `systemd-logind` kept `LidClosed = true`. When waking from hibernate at 22:10 with the lid open, no event was delivered. After `HoldoffTimeoutSec=30s`, `systemd-logind` saw `LidClosed == true` and re-suspended every 30 seconds.
    3. Concurrently, IPTS touchscreen hardware disconnected upon wake, causing `iptsd` to hang on an IOCTL and block systemd for 14 seconds until terminated by `SIGKILL`.
  - **Fix**:
    1. Configured `button.lid_init_state=open` in [`/etc/default/limine`](file:///etc/default/limine). Unlike `method`, `open` executes `acpi_lid_notify_state(button, true)` without calling `acpi_pm_wakeup_event()`, preventing snapshot aborts while guaranteeing `systemd-logind` receives `SW_LID = 0` (open) upon resume, preventing the 30s loop.
    2. Created IPTS post-resume hook [`profiles/surface/systemd/21-surface-ipts-resume.sh`](file:///home/jmvp/dotfiles/profiles/surface/systemd/21-surface-ipts-resume.sh) deployed to `/etc/systemd/system-sleep/21-surface-ipts-resume.sh` to trigger udev re-enumeration after 1s.
    3. Created drop-in [`profiles/surface/systemd/iptsd-timeout.conf`](file:///home/jmvp/dotfiles/profiles/surface/systemd/iptsd-timeout.conf) deployed to `/etc/systemd/system/iptsd@.service.d/timeout.conf` with `TimeoutStopSec=3s` to prevent hung touch nodes from stalling sleep transitions.
    4. Updated [`profiles/surface/setup.sh`](file:///home/jmvp/dotfiles/profiles/surface/setup.sh) to automate deployment of all components. Documented Section 3 in [`profiles/surface/gotchas/sleep-hibernate.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/sleep-hibernate.md).
- **Surface Book touchscreen & stylus wake race condition recovery (`surface`, 2026-09-24)**:
  - **Issue**: Touchscreen and Surface Pen completely unresponsive after waking from sleep/suspend. `hyprctl devices` missing `iptsd-virtual-touchscreen` and `iptsd-virtual-stylus`; 0 active `iptsd` systemd units.
  - **Root Cause**: During wake at 18:36:44 MDT, IPTS hardware re-enumerated from `hidraw0` to `hidraw6`. Kernel driver logged `ipts: FEEDBACK: recv failed: -11` (`-EAGAIN`) while thawing. Udev rule `/usr/lib/udev/rules.d/50-iptsd.rules` immediately executed `/usr/bin/iptsd-check-device --quiet /dev/hidraw6`, which failed due to transient device unavailability. Udev aborted rule evaluation, dropping `TAG+="systemd"` and never queuing `iptsd@dev-hidraw6.service`. Old daemon instance `iptsd@dev-hidraw0.service` exited upon `hidraw0` removal, leaving the daemon stopped and virtual touchscreen uninstantiated.
  - **Fix**: Executed `sudo udevadm trigger --action=add /dev/hidraw6` via interactive Kitty terminal per Rule 8, prompting udev to re-validate `hidraw6`, tag with `systemd`, and start `iptsd@dev-hidraw6.service`.
  - **Verification**: `systemctl status iptsd@dev-hidraw6.service` active and running; `hyprctl devices` confirmed `iptsd-virtual-touchscreen-045e:09b2` and `iptsd-virtual-stylus-045e:09b2` re-registered in Hyprland. Documented root cause, architecture, and recovery options in `profiles/surface/gotchas/touchscreen-iptsd.md` (symlinked to `references/gotchas/touchscreen-iptsd.md`).
- **OpenCode TUI line navigation (`SUPER + Left / Right` & `Home / End`) (`core`, 2026-09-22)**:
  - **Issue**: Pressing `SUPER + Left` or `SUPER + Right` in OpenCode input prompts jumped to first/last message in session history instead of moving cursor to beginning/end of line.
  - **Root Cause**: Hyprland translates `SUPER + Left` / `SUPER + Right` to simulated `Home` / `End` keys. OpenCode's default keymap assigns `Home` and `End` to `messages_first` and `messages_last`, while cursor navigation defaults strictly to Emacs keys (`Ctrl + A` and `Ctrl + E`).
  - **Fix**: Created universal dotfiles configuration [`core/.config/opencode/cli.json`](file:///home/jmvp/dotfiles/core/.config/opencode/cli.json) symlinked to `~/.config/opencode/cli.json`, patching `keybinds` to map `home` and `end` to `input_line_home` and `input_line_end` (and `shift+home` / `shift+end` to `input_select_line_home` / `input_select_line_end`) while preserving `ctrl+g` / `ctrl+alt+g` for message history navigation.
  - **Verification**: Executed `opencode reload` (returned `Configuration reloaded`); verified symlink integrity and config validation. Documented in `references/gotchas/opencode.md`.
- **Surface Book dual-battery 201% calculation desync & automated watchdog (`surface`, 2026-09-20)**:
  - **Issue**: Battery indicator displayed impossible 201% (`DisplayDevice percentage: 200.813%`) while discharging.
  - **Root Cause**: At 13:00:33 MDT, base battery `BAT2` experienced a transient EC serial communication timeout (`power_supply BAT2: driver failed to report 'manufacturer' property: -110`). Upstream UPower bug #336 reset D-Bus `BAT2.EnergyFull` to 0 but retained internal cache comparison variables. When `BAT2` recovered, UPower skipped re-publishing `EnergyFull` because sysfs matched its stale cache. `DisplayDevice` summed total charge (29.64 Wh) and divided only by tablet battery `BAT1` full capacity (14.76 Wh). Earlier fix on 2026-09-17 was only a manual one-time service restart without an automated daemon.
  - **Fix**: Created automated watchdog `/usr/local/bin/surface-battery-watchdog` (tracked in `profiles/surface/scripts/surface-battery-watchdog.sh`) to detect when sysfs has healthy `BAT2` energy but UPower reports 0 Wh or `DisplayDevice > 100%`, restarting `upower.service` with a 30s rate-limiting guard and refreshing Noctalia (`noctalia msg config-reload`). Deployed `surface-battery-watchdog.service`, `surface-battery-watchdog.timer` (2-minute interval), `/etc/udev/rules.d/99-surface-battery.rules` (`BAT2` change events), and `/etc/systemd/system-sleep/20-surface-battery-resume.sh` (sleep wake hook) via `profiles/surface/setup.sh`.
  - **Verification**: Executed watchdog; `DisplayDevice` restored to healthy ~45% (28.75 Wh / 63.9 Wh), `BAT2` full capacity restored to 49.14 Wh, timer active and waiting, 0 `hyprctl configerrors`.
- **GNOME Keyring greetd PAM auto-unlock & Seahorse setup (`surface`, 2026-09-20)**:
  - **Issue**: GNOME Keyring was locked (`Locked: 1`) on boot, causing token and credential access from CLI tools (`agy`, `gh`) and applications to block and pop up password prompts (`gcr-prompter`).
  - **Root Cause**: Greetd login manager configuration (`/etc/pam.d/greetd`) lacked `pam_gnome_keyring.so` integration. Keyring was named `Default_keyring` instead of standard `login`.
  - **Fix**: Backed up `/etc/pam.d/greetd` to `/etc/pam.d/greetd.bak` and added `pam_gnome_keyring.so` to `auth`, `session`, and `password` sections. Installed `seahorse` for graphical keyring management.
- **Surface Modern Standby hibernation failure & 19-hour sleep limbo (`surface`, 2026-09-20)**:
  - **Issue**: After 90 minutes of sleep, `systemd-suspend-then-hibernate` failed to power off the laptop. The machine either aborted within 12 seconds due to Surface Aggregator Module (SAM) EC timeout (`surface_dtx: failed to get base state: -19`) or hung in a frozen 19-hour sleep limbo with the lid closed (`Sep 19 10:22 -> Sep 20 05:20`) without powering down, draining battery continuously.
  - **Root Cause**: Modern Standby Surface Book 3 firmware does not support traditional ACPI S4 platform sleep. Default `HibernateMode=platform` caused ACPI S4 rejection and hang. Furthermore, default `SuspendEstimationSec=60min` caused an unnecessary intermediate RTC wake at 60 minutes.
  - **Fix**: Updated [`/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf`](file:///etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf) with `HibernateMode=shutdown` (forcing clean ACPI S5 power-off after writing the RAM snapshot to NVMe swap `/dev/nvme0n1p3`) and `SuspendEstimationSec=90min`. Reloaded systemd daemon.
  - **Documentation**: Documented issue, live journal traces, and fix in [`profiles/surface/gotchas/sleep-hibernate.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/sleep-hibernate.md) (symlinked into `references/gotchas/sleep-hibernate.md`).
- **System clock desynchronization after S4 hibernation (`surface`, 2026-09-20)**:
  - System clock was 7 hours behind (~05:25 AM MDT vs true ~12:25 PM MDT / 18:25 UTC) after waking from S4 hibernation (`suspend-then-hibernate`).
  - Read-only diagnostics revealed the hardware RTC restored an out-of-sync timestamp upon S4 resume while `systemd-timesyncd` remained idle with a 34-minute poll interval without automatically triggering an NTP handshake upon wake or Wi-Fi reconnect.
  - User approved fix via interactive elevated Kitty terminal: restarted `systemd-timesyncd.service` to immediately step the system clock forward (+6h 59min 55s offset corrected) and sync RTC.
  - Installed persistent automatic resume hook in `/etc/systemd/system-sleep/10-timesyncd-resume.sh` and NetworkManager dispatcher hook in `/etc/NetworkManager/dispatcher.d/no-wait.d/10-timesyncd.sh` to trigger timesyncd synchronization on sleep wake and interface connection.
  - Documented root cause, hooks, and verification in `references/gotchas/networking.md`.

### Added
- **Dynamic Kitty focus-dependent background opacity (`surface` / `core`, 2026-09-22)**:
  - **Feature**: Dynamic terminal background transparency that shifts from `0.60` (unfocused) to `0.75` (focused), preserving 100% solid text glyphs and font contrast without darkening or fading syntax highlighting.
  - **Implementation**:
    - Created lightweight event-driven daemon [`core/.local/bin/kitty-focus-opacity`](file:///home/jmvp/dotfiles/core/.local/bin/kitty-focus-opacity) symlinked to `~/.local/bin/kitty-focus-opacity`.
    - Listens directly to Hyprland's UNIX event socket (`.socket2.sock`) for window focus events and modulates Kitty background opacity via DCS Device Control Strings (`\x1bP@kitty-cmd`) over Kitty's private UNIX domain socket (`/run/user/1000/kitty-socket-<pid>`).
    - Configured [`core/.config/kitty/kitty.conf`](file:///home/jmvp/dotfiles/core/.config/kitty/kitty.conf) with `dynamic_background_opacity yes`, `allow_remote_control socket-only`, and `listen_on unix:${XDG_RUNTIME_DIR}/kitty-socket`.
    - Registered autostart in [`core/.config/hypr/config/autostart.lua`](file:///home/jmvp/dotfiles/core/.config/hypr/config/autostart.lua) via `hl.exec_cmd(homeDir .. "/.local/bin/kitty-focus-opacity")`.
  - **Verification**: Verified zero CPU utilization while idle, systemd user service `kitty-focus-opacity` active and responsive, and clean Hyprland config validation (`hyprctl configerrors` returned 0).
- **Core Rule 9: Device-Specific vs. Universal Scope Identification (`agents`, 2026-09-20)**:
  - Added Rule 9 to [`SKILL.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/SKILL.md), [`SKILL.md.template`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/SKILL.md.template), and [`AGENTS.md`](file:///home/jmvp/dotfiles/AGENTS.md).
  - Mandates that whenever a new package, daemon, script, keybinding, or setting is introduced, the agent must explicitly classify it as hardware profile-specific (`profiles/<profile>/`) or universal (`core/`).
  - Added an ambiguity guard: if it is unclear whether a feature is hardware-dependent or universal, the agent must ask the user for clarification before applying or placing the configuration.

### Changed
- **Persistent Surface LZ4 hibernation default applied and verified (`surface`, 2026-10-08)**:
  - User separately approved persistence after the real 18s→15s lid-to-lock pair and controlled userspace codec measurements. Added Surface-only `scripts/surface-hibernate-compressor.sh` and boot oneshot `systemd/surface-hibernate-compressor.service`, plus guarded absent/identical-only profile deployment. It requires Surface hardware / `*-surface`, loads the crypto provider, verifies passed self-test, preserves unexpected/concurrent choices and reads back the selector; fallback kernels retain defaults.
  - Narrow interactive sudo installer re-inspected the matching boot image and protected hashes, refused sleep jobs or preexisting targets/units/links, saved a root manifest/payload backup, exclusively installed the two files, verified/enabled/started the service and read back **LZ4**. Scoped failure cleanup was prepared to restore LZO without discarding others' changed configuration; no rollback was needed on this successful application. No Limine argument/menu, initramfs compression/rebuild, sleep policy, IPTS, image-size, battery hook, package or reboot/hibernate change was made.
  - Bash/unit-condition/staged-unit checks, 11 mocked helper scenarios, four installer workflows, exclusive file/symlink conflicts and queued-sleep/concurrency rollback guards passed without real privileged operations during preparation. **Live activation then succeeded**: enabled / active (exited), result success / exit 0, root-owned helper `0755` and unit `0644`, expected installed hashes and enablement link verified. Journal records successful `lz4` read-back. Actual initramfs/hash and protected before/after state match; original boot retained. Independent follow-up found healthy iptsd PID `41636`, both virtual inputs and no failed units/Hyprland errors. Physical touch not newly retested; cold boot/another restore not requested or tested. Backup: `/var/backups/surface-hibernate-lz4-20261008-191458-43170/`; evidence: `~/.cache/opencode/surface-standby-tests/lz4-persistent-eq_82i4s/completed.json` and `followup.json`. Documented method and interactive rollback in sleep gotcha section 10, current state and config-paths index; no commit/push.
- **Full system package upgrade via yay & reboot (`surface` / `core`, 2026-10-08)**:
  - **Action**: Upgraded ~120 repository packages via interactive `yay -Syu` session per Rule 8, followed by a clean reboot.
  - **Upgrades**:
    - **Compositor & Wayland Shell**: `hyprland` (0.56.2-3.1 $\rightarrow$ 0.56.2-4.1), `noctalia` (5.2.0 $\rightarrow$ 5.2.1), `noctalia-greeter` (1.5.0 $\rightarrow$ 1.6.0), `xorg-xwayland` (24.1.13 $\rightarrow$ 24.1.14).
    - **System & Power**: `upower` (1.91.4 $\rightarrow$ 1.91.5), `mkinitcpio` (42.1 $\rightarrow$ 42.2), `networkmanager` (1.58.1-1 $\rightarrow$ 1.58.1-2), `openssh` (10.5p1 $\rightarrow$ 10.6p1), `device-mapper` / `lvm2` (2.03.42 $\rightarrow$ 2.03.43).
    - **Applications & Tools**: `zen-browser-bin` (1.22.3b $\rightarrow$ 1.23.1b), `firefox` (157.0 $\rightarrow$ 157.0.1), `dolphin` (26.08.1 $\rightarrow$ 26.08.2), `lazygit` (0.65.1 $\rightarrow$ 0.66.0), `qemu-system-x86` (11.1.1-4 $\rightarrow$ 11.1.2-1), `rust` (1.98.1 $\rightarrow$ 1.99.0).
    - **Toolkits & Desktop Libraries**: `gtk3`, `gtk4`, `glib2`, and `qt6-*` (6.11.2 $\rightarrow$ 6.12.0).
  - **Verification**: Clean reboot; 0 `hyprctl configerrors`, eDP-1 scale 2, clean system state, updated `references/current-state.md`.
- **Documentation profile scope separation & hygiene (`multi-pc` / `surface`, 2026-10-08)**:
  - **Action**: Aligned [`references/config-paths.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/config-paths.md), [`references/gotchas.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/gotchas.md), and [`SKILL.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/SKILL.md) with Core Rule 9.
  - **Scope Isolation**: Removed legacy MacBook T2 entries from `config-paths.md`. Explicitly separated universal scripts (`core/.local/bin/`) from hardware-specific Surface configurations (`profiles/surface/`), ensuring Surface daemon scripts (`surface-battery-watchdog`, `surface-unplug-lid-handler`), systemd drop-ins, and on-screen keyboard wrapper remain strictly quarantined within `profiles/surface/` and out of `core/`.
  - **Gotchas Index**: Cleaned up obsolete `/home/java1127/` paths in `gotchas.md`, indexed all Surface profile gotchas, and added missing entries (`opencode.md`, `virtual-keyboard.md`) to `SKILL.md`.
- **Full system package upgrade via yay (`surface` / `core`, 2026-10-01)**:
  - **Action**: Performed complete system upgrade via interactive `yay -Syu` terminal session on active Wayland workspace per Rule 8.
  - **Upgrades**: Upgraded 259 repository packages, including:
    - **System & Init**: `systemd` (261.3 $\rightarrow$ 262-1), `glibc` (2.44+r24 $\rightarrow$ 2.44+r50), `intel-ucode` (20260812 $\rightarrow$ 20260925), `linux-firmware` (20260910 $\rightarrow$ 20260916), `mkinitcpio` (42 $\rightarrow$ 42.1), `limine-mkinitcpio-hook` (1.37.1 $\rightarrow$ 1.39.0), `limine-snapper-sync` (1.31.0 $\rightarrow$ 1.32.0).
    - **Desktop & Wayland**: `noctalia` (5.1.0 $\rightarrow$ 5.2.0), `kitty` (0.48.2 $\rightarrow$ 0.49.2), `aquamarine` (0.15.0 $\rightarrow$ 0.15.1), `hyprtoolkit` (0.5.4 $\rightarrow$ 0.6.0), `libinput` (1.31.3 $\rightarrow$ 1.32.0), `swayimg` (5.6-1.1 $\rightarrow$ 5.6-2.1).
    - **Graphics & Audio**: `mesa` & `vulkan-intel` (3:26.2.2 $\rightarrow$ 3:26.2.4), `pipewire` (1.6.8 $\rightarrow$ 1.6.9), `wireplumber` (0.5.17 $\rightarrow$ 0.5.18), `easyeffects` (8.2.9 $\rightarrow$ 8.3.0).
    - **Browsers & Applications**: `zen-browser-bin` (1.22.1b $\rightarrow$ 1.22.3b), `firefox` (155.0.1 $\rightarrow$ 157.0), `brave-origin-bin` (1:1.95 $\rightarrow$ 1:1.96), `git` (2.55 $\rightarrow$ 2.56), `github-cli` (2.101 $\rightarrow$ 2.102), `qemu-system-x86` (11.1.1-2 $\rightarrow$ 11.1.1-4), `wimlib` (1.14.5-3 $\rightarrow$ 1.14.5-4), `ntfs-3g` / `ntfsprogs` (2026.7.7 $\rightarrow$ 2026.9.28).
  - **Kernel & Surface Continuity**: Verified `linux-surface` remains untouched at `6.19.8-arch1-3-surface`. Initramfs regenerated across all installed kernels while preserving all Limine kernel parameters (`button.lid_init_state=open`).
  - **Post-Upgrade Maintenance**: Restarted Noctalia into v5.2.0; verified 0 `hyprctl configerrors`, clean input device registration (`iptsd` touchscreen/pen, touchpad), and updated `references/current-state.md`.
- **Migrated NTP daemon from systemd-timesyncd to chrony (`surface`, 2026-09-22)**:
  - **Issue**: Surface Book 3 hardware RTC desyncs after S4 hibernation/sleep. `systemd-timesyncd` has an exponential poll backoff up to 34 minutes, treats multi-hour offsets as spikes, and resume hooks failed due to Wi-Fi association timing races.
  - **Solution**: Switched to `chrony 4.9-1.1` (tracked in `core/packages.txt`). Configured `/etc/chrony.conf` with `makestep 1 -1` (unconditional immediate stepping on any offset > 1s) and `rtcsync` (kernel 11-minute RTC synchronization). Disabled `systemd-timesyncd.service` and purged obsolete resume scripts (`/etc/systemd/system-sleep/10-timesyncd-resume.sh` and `/etc/NetworkManager/dispatcher.d/no-wait.d/`). Deployed official NetworkManager dispatcher script (`/etc/NetworkManager/dispatcher.d/20-chrony-onoffline.sh`) to instantly burst NTP queries when internet connects.
  - **Verification**: `chronyd.service` active and enabled; `chronyc tracking` synchronized with sub-millisecond precision across 4 pool servers; `timedatectl status` confirms `System clock synchronized: yes` and `NTP service: active`.
- **OpenCode CLI upgraded to v2.0.14 (`surface`, 2026-09-22)**:
  - **Action**: Ran `opencode upgrade` to update OpenCode from `v2.0.8` to `v2.0.14`.
  - **Gotcha Handled**: Initial upgrade check failed due to a 5.5-hour system clock drift after sleep/hibernate causing TLS certificate validation failure (`certificate is not yet valid`). Resolved by restarting `systemd-timesyncd.service` to step the system clock forward and resynchronize with NTP.
  - **Service Verification**: Restarted background daemon via `opencode service restart`; verified `opencode --version` returns `v2.0.14` in both bash and fish shells, background service is active at `http://127.0.0.1:49374`, and subsequent `opencode upgrade` reports `2.0.14 is already installed`.
- **Modular Hardware Profile Separation & Core Hygiene (`multi-pc`, 2026-09-20)**:
  - **MacBook T2 Profile Isolation**: Relocated `core/.config/easyeffects/` (`output/mbp.json` and DSP preset) to `profiles/macbook-t2/.config/easyeffects/`. Moved `easyeffects` package from `core/packages.txt` to `profiles/macbook-t2/packages.txt`. Removed hardcoded `apple::kbd_backlight` listener from universal `core/.config/hypr/hypridle.conf` (fixing repeating 2.5-minute errors on non-Apple hardware). Extracted Touch Bar and AMDGPU power-switching logic from `core/.local/bin/hypr-lid-handler` into dedicated profile hooks in `profiles/macbook-t2/.config/hypr/hooks/`.
  - **Surface Profile Isolation**: Relocated on-screen virtual keyboard wrapper `core/.local/bin/hypr-virtual-keyboard` to `profiles/surface/.local/bin/hypr-virtual-keyboard`. Version-controlled Surface Modern Standby sleep drop-ins in `profiles/surface/systemd/` and added automated deployment to `profiles/surface/setup.sh`.
  - **ASUS Zephyrus Legacy Quarantine**: Moved legacy ASUS ROG AniMe Matrix charging script and launcher (`anime-lid-charging`, `AniMatrix.desktop`) out of `core` into `profiles/asus-rog/`.
  - **Installer & Stow Updates**: Updated `install.sh` and `profiles/surface/.stow-local-ignore` with `--ignore=^systemd` to prevent stow collisions with system drop-ins. Executed `install.sh --only-stow` on `surface` and verified clean symlinks with zero `hyprctl configerrors`.

### Investigated
- **Controlled LZO/LZ4 codec-only benchmark without hibernation (`surface`, 2026-10-08)**:
  - At user request, built an unprivileged native C test using already-installed LZO 2.10/LZ4 1.10.0. Identical four fixed 8 MiB public/synthetic fixtures, 128 KiB blocks (upstream 32-page unit), three warm-ups, calibrated ~80 ms batches, 12 balanced paired rounds per codec/operation, CPU-3 affinity only for the benchmark, and separate monotonic-raw wall/thread CPU timing. No Python/file IO/verification in timed work; sizes, context switches/page faults and sampled clocks/temperature recorded. Fixture/source/library hashes and raw samples retained. No private RAM read, sudo/install, hibernation/suspend, kernel-module/swap/configuration operation.
  - **Results (192 samples)**: Median paired LZ4/LZO compression/decompression throughput **1.10× / 3.71× mixed pages**, **1.32× / 5.87× installed binaries**, **0.75× / 1.00× incompressible**, **1.01× / 7.93× all-zero control**. Mixed payload 0.22% smaller with LZ4; binary payload 3.58% larger. Zero payload smaller but identical emulated page-padded bytes; incompressible data expands slightly with either codec. Mixed decode IQR 3.62–3.80×, full range 3.57–3.93×. All exact roundtrips passed; no timed page faults. Five incompressible samples exceeded 2% off CPU and were flagged, not discarded; CPU-time directions agree. Temperature 53–57°C; power-saver/powersave preserved, clocks and background/sibling activity not fixed.
  - **Safety/limits**: Before/after kernel/boot ID, LZO selection, image-size/resume/thread controls, readable sleep/recovery hashes, governor/profile and module names unchanged. Boot config unreadable unprivileged and not modified. Userspace implementations are not exact kernel codecs; single-thread warm-cache data is not a RAM image, and real hibernation has multiworker/checksum/copy/IO/firmware/device costs. No exact wake-speed, real image-size or battery/overnight prediction, and no permanent LZ4 authorization. Sanitizer roundtrips on four fixtures, 48 timing-loop smoke samples, seven invalid-input rejections and pairing/order/noise-statistics checks passed. Evidence: `~/.cache/opencode/surface-standby-tests/codec-lab-eyxw8afi/README.md`, `preparation-validation.json`, and successful `run-xyu17qq1/report.json`; gotcha section 9/current state updated. LZO remains active.
- **LZ4 hibernation A/B pair passed; LZO rollback verified (`surface`, 2026-10-08; timing gain preliminary)**:
  - Rechecked Surface kernel `6.19.8-arch1-3-surface`, LZO selection, on-AC charging with both batteries/base present, ample active NVMe swap, and `power-saver` profile. The LZ4 crypto module dependency dry-run resolves; only its library is already loaded for zram, not the hibernation crypto provider.
  - Prepared a read-only actual Surface-entry/initramfs inspection with boot-content hash checks and codec/module-loader/resume-helper presence guards, followed by a user-confirmed LZO baseline with external stopwatch observations. The temporary LZ4 trial followed only after verification, with LZO restored afterward. No module load, compressor write, boot/initramfs rebuild, package install, or sleep-policy change occurred during preparation.
  - Actual selected Surface image verified: LZ4 crypto/dependency modules, alias/dependency metadata, module loader, and resume helper are present; kernel/initramfs BLAKE2b checks pass. Image SHA-256 `7afeeae49dcec0a3953c9877639cf1230d2bb11e1202deebefe0489c26f5f515`. No boot-image rebuild needed.
  - Direct LZO baseline restored the original session/collector, with iptsd and automatic healthy-daemon preservation intact. User reported **14s to hibernate / 18s lid-open to first lock screen**; hibernate timing boundaries were not further specified. Captured chat timing separately because the terminal observation form was still open.
  - Prepared temporary LZ4-only trial with confirmed module load/self-test, parameter read-back, journal-confirmed operation completion, and automatic verified LZO rollback before observations. The journal wait is essential: `systemctl hibernate` may return when merely queued, so immediate rollback would invalidate the trial. Six selector/rollback scenarios, four completion cases, a queued-wait case, and three mocked workflows (success/request failure/module-load failure) passed without real module/sysfs/sleep actions. The actual restore result is recorded below; a single pair remains preliminary. Evidence: `~/.cache/opencode/surface-standby-tests/lz4-ab-75k6c24s/`; measurement limits in `profiles/surface/gotchas/sleep-hibernate.md`, section 9.
  - **Stopped launch clarified; password wait only**: User reported `LZ4 trial stopped.` without preflight/error/codec records, then clarified they were AFK at the sudo password prompt. Same boot remained active with LZO selected, no LZ4 provider, no hibernate job, and no failed units; the privileged trial had not begun. Script syntax checks passed. At user request, reopen with fresh capture files and startup stderr logging; module/parameter changes and hibernation still require explicit `HIBERNATE`. This is not a LZ4 compression/restore failure. Evidence: `lz4-trial/launch-stop-analysis.json`.
  - **Confirmed LZ4 trial succeeded**: After exact `HIBERNATE` confirmation, `crypto-lz4` loaded successfully and `lz4-scomp` self-test passed; the compressor read back `lz4` before/after restoration. Original boot/session/collector survived. User recorded **12s confirmation-to-full-power-off / 15s lid-open-to-first-lock-screen**, lid wake, full power-off, and working touch. Automatic IPTS worker completed its healthy-daemon check; `iptsd@dev-hidraw6.service` PID `41636` and both virtual inputs were healthy at follow-up, with no failed units or Hyprland errors. Admin/capture stderr logs empty. Evidence: `lz4-trial-retry-8mlx_s1d/`.
  - **Automatic trial rollback and limits**: After journal-confirmed operation completion, LZO was restored/read-back before observations; no persistent selection was created by the trial. Provider stayed loaded; kernel/initramfs hashes, boot/sleep/recovery configuration, resume device and `3109138432`-byte image-size target were unchanged. No package install or rebuild. Reported wake time **18s → 15s (3s / ~17% lower)** in one pair; reported hibernation **14s → 12s** has less precise LZO boundaries. Memory differed (allocated `756340` vs `746321` pages), apps were not independently controlled, and actual compressed-image size/codec-only timing were not measured. Both trials on AC, so no battery-drain finding. LZO baseline observation form was never saved; chat supplies its timing/wake but not a separate physical-touch check. Clock later stepped **+41.468226s**, so journal intervals are not external timings. Repeatability, overnight reliability, pen, and automatic delayed hibernation with LZ4 remain untested. Persistence was subsequently approved/applied in the Changed entry above. Consolidated trial evidence: `lz4-ab-75k6c24s/comparison-analysis.json`.
- **Further hibernation optimization and missing post-resume IPTS daemon (`surface`, 2026-10-08; runtime recovered and automatic hook dispatch verified)**:
  - Read-only follow-up found `iptsd@dev-hidraw0.service` failed with a stop timeout/SIGKILL during the automatic hibernation cycle; the replacement `iptsd@dev-hidraw6.service` started and then stopped. No `iptsd` process was running at follow-up despite the live `045E:09B2` IPTS HID device being present. Existing 3-second stop guard and 1-second resume hook were preserved; exact lifecycle failure, user-visible touch/pen behavior, and latency impact remain unconfirmed.
  - Hibernation compressor was LZO at this initial follow-up. Running-kernel `CONFIG_CRYPTO_LZ4=m`, the installed LZ4 crypto module, and mkinitcpio hooks requesting both codecs established LZ4 as a potential performance experiment **without a custom kernel rebuild**. The unset `CONFIG_HIBERNATION_COMP_LZ4` option is a default-compressor choice, not proof that LZ4 is unsupported. Active-image codec inclusion and one successful LZ4 restore were subsequently verified in the approved A/B work above; the trial restored LZO, then a separately approved persistent default selected LZ4 (Changed entry). Repeatable wake-time gains remain unproven.
  - No compressor/image-size setting, module state, kernel argument, or package was changed. Evidence: `~/.cache/opencode/surface-standby-tests/hibernate-35min-dvh4l4ii/optimization-followup.json`; interpretation and next-step cautions documented in `profiles/surface/gotchas/sleep-hibernate.md`, section 9.
  - **Recovery implementation deployed at user request**: Added Surface-only helper/unit, converted the sleep hook to nonblocking pre-stop/post-restart dispatch, corrected the scanned-directory registration, and updated profile deployment. The worker retains the 1-second guard, targets only a rediscovered/probed IPTS touchscreen, explicitly starts the inactive matching daemon, retries within a 45-second unit bound, and preserves healthy instances. Bash checks, seven recovery and ten registration mock scenarios, guarded installation, manual inactive-daemon recovery, and one real registered-hook dispatch cycle passed. User confirmed touch and lid-only restore; pen, an induced-race cycle, and overnight reliability remain untested. Evidence: `~/.cache/opencode/surface-standby-tests/ipts-recovery-z4wvl2hs/`; see the Fixed entry above.
- **Surface Book 3 real S0ix entry confirmed (`surface`, 2026-10-08)**:
  - Read-only, user-operated battery-only lid-close test on `6.19.8-arch1-3-surface`: PMC counter increased by 321.9876 seconds during a 322.566392-second kernel suspend interval, **99.82% S0ix residency**. One clean suspend/resume cycle was logged; existing 30-minute suspend-then-hibernate settings were preserved.
  - Corrected the inference from earlier zero counters: they became nonzero after this test, so zero before the first sleep is not evidence of broken S0ix. No firmware-state workaround or sleep tuning was needed to achieve entry in this cycle.
  - Combined battery energy fell by 0.19 Wh across 369.696133 seconds, including 47.129741 seconds awake. This does **not** isolate standby power or establish overnight reliability or Windows/macOS parity.
  - **Longer repeat**: A second battery-only lid-close cycle lasted approximately 20 minutes 32 seconds, with **approximately 100% S0ix residency** and no intermediate full resumes logged. PMC and journal timing differ by 0.756146 seconds, so the raw 100.061% ratio is not a literal physical residency percentage.
  - The longer capture lost 0.40 Wh combined (tablet 0.25 Wh, base 0.15 Wh) across 1262.148080 boottime seconds: **1.14 W whole-capture average, including roughly half a minute awake**. Sustained S0ix entry is confirmed, but isolated standby power and overnight behavior remain unmeasured. The 30-minute hibernation policy was retained.
  - Longer-test evidence: `~/.cache/opencode/surface-standby-tests/20min-fv705gun/`.
  - **Read-only PMC/device follow-up** (awake on AC): Cumulative package C10 residency is nonzero; all captured USB devices were runtime-suspended with automatic runtime PM, Wi-Fi live power saving was on, and `power-profiles-daemon` was using `power-saver`. No definite standby-power culprit was identified; awake PCI/audio settings are not proof of sleep-time power use.
  - Ice Lake exposes no separate S0ix substate counters through this PMC interface, so minimum whole-platform power cannot be verified from it. Skipped `slp_s0_debug_status` because its upstream read callback performs a debug-latch reset/register write; no latch or power settings were changed.
  - Follow-up evidence: `~/.cache/opencode/surface-standby-tests/pmc-devices-m_7wd6iw/`; documented in `profiles/surface/gotchas/sleep-hibernate.md`, section 6. Retain the 30-minute safeguard.
  - **Automatic hibernation/restore passed**: In a supervised 35-minute battery-only lid test, hibernation started approximately **30 minutes 5 seconds after lid closure**. The original boot ID and capture PID survived, the service completed with `Result=success` / `ExecMainStatus=0`, and `[shutdown]` was selected. User reports **lid-only restoration in 10–30 seconds**, with no power-button press needed.
  - **Timing/counter caveats**: PMC counter reset to zero across hibernation, preventing a valid S0ix delta for this test. Wall time exceeded boottime by approximately 370.09 seconds; `chronyd` confirmed a forward step of 370.092634 seconds after restoration. The raw approximately 8.4-second journal hibernation interval is not time powered off or proof of an instant abort.
  - Combined energy loss was **0.65 Wh** across a 37-minute-9-second capture, including suspend, hibernation transition/restore, hibernated time, and awake overhead. This does not isolate standby/hibernated power or establish overnight reliability. No system configuration changes or package installs were made.
  - Automatic-cycle evidence: `~/.cache/opencode/surface-standby-tests/hibernate-35min-dvh4l4ii/`; findings and user wake observations documented in `profiles/surface/gotchas/sleep-hibernate.md`, section 7.
  - Evidence: `~/.cache/opencode/surface-standby-tests/test-pz4boori/`; interpretation documented in `profiles/surface/gotchas/sleep-hibernate.md`, section 5. No system configuration changes or package installs performed.
- **Portable Windows USB first boot failed; preparation defects identified (`surface`, 2026-09-18)**:
  - User reached recovery OOBE with built-in input unavailable. Corrected the earlier readiness claim: only file/EFI hashes had been checked, not a working Windows installation.
  - Read-only collection found Plug and Play unavailable (`0xE0000223`), recovery OOBE active, and no installed Surface drivers. Image application through a Linux NTFS mountpoint discarded Windows ACLs, attributes, and extended attributes; copying driver files did not install them.
  - User approved native-DISM rebuild and offline driver installation, followed by actual VM desktop/service/driver-policy verification. Details and persistent evidence paths are in `profiles/surface/gotchas/battery-upower.md`, section 3.
  - **Repair completed and verified same day**: the rebuilt stick booted to the Windows desktop in an isolated VM; in-Windows report confirmed Plug and Play running, SAN policy 4, `PortableOperatingSystem=1`, all 41 driver packages installed with zero missing. The VM's `usb-storage` transport produced an OVMF-specific `0xc0000428`; the same disk boots via SATA, and the Surface's earlier USB boot manager run shows the real firmware accepts the stick. Native Surface charging retest pending.
- **Direct base firmware interface discovered (`surface`, 2026-09-17)**:
  - At user request to investigate reverse engineering, decoded cached Surface base HID descriptors and identified a CFU-compatible collection on `01:15:02:05:00` (`045E:09A6`, currently `hidraw2`). Stock fwupd's USB-backed CFU transport does not directly cover the Surface Aggregator `BUS_HOST` interface.
  - An identity-checked, read-only `HIDIOCGFEATURE` query for report `0x20` successfully returned 61 bytes through an interactive sudo terminal. Header reports three records and protocol revision 4; the probe's exit code 2 was its deliberate rejection of unverified revision-4 interpretation, not failed communication.
  - **Component mapping completed same day**: range-fetched five small files from Microsoft's official `SurfaceBook3_Win11_22621_25.013.34389.0.msi` (full 1.67 GB never downloaded; ~116 MB bounded range reads) and hash-verified them against the MSI `MsiFileHash` table. Live `0x12`/`3.6.1` matches `SurfaceBookBaseV3_PD.offer.bin`; live `0x10`/`10.602.139` matches both KIP offer blobs; live `0xFE`/`0.0.0` is the expected CFU offer-information sentinel. All base components are current, so stale base firmware does not explain the charging fault.
  - Preserved raw response, descriptor hash, temporary probe/log paths, transport evidence, offer mapping, and file hashes in the Surface battery/USB-C gotcha. Charging remains unresolved; no firmware write was performed.
- **USB-C charging failure after monitor connection (`surface`, 2026-09-16–17; unresolved)**:
  - User reports failure across reboot/OS reinstall, three chargers, different known-good cables, the proposed recovery test, and charging the detached base. Surface Connect charging and USB-C external video work; only CachyOS is installed.
  - Read-only samples: kernel `ADP1 online=0`, tablet battery not charging, base battery discharging; UPower agrees and reports plausible combined capacity. UEFI `23.101.140` and SAM `10.600.139` match the newest respective entries in Microsoft's published Book 3 history; base/PD controller firmware was not fully inventoried.
  - With the confirmed 60 W portable charger connected, captured 30 raw `ADP1 online` transitions in 40 seconds; base battery stayed discharging and fell from 23.84 Wh to 23.68 Wh. This localizes the symptom below the desktop indicator but does not identify a particular failed controller or establish firmware corruption.
  - September 17 `fwupd` inventory exposed six main UEFI capsule resources but no dedicated base/USB-C update target; CFU plugin ready, no matching base profile in installed quirks. LVFS metadata refresh succeeded with 0 supported detected devices; `get-updates --json` returned an empty list. A follow-up direct CFU read plus official-package offer mapping verified all base components current (PD `3.6.1`, KIP `10.602.139`); this does not establish a defective controller IC. Recorded raw capsule GUIDs/versions and interpretation limits in `profiles/surface/gotchas/battery-upower.md` (already symlinked into the skill). No firmware flash performed.
### Added
- **Portable Windows diagnostic USB initial preparation (`surface`, 2026-09-17–18; first boot subsequently failed)**:
  - 128 GB Lexar USB (verified by serial/size/labels at destructive steps) received Windows 11 Enterprise Evaluation 25H2 (SHA-256-verified Microsoft image) and its own ESP + `bcdboot` UEFI boot files; hashes of `bootmgfw.efi`/`winload.efi` matched the verified image. This did not prove setup completion or driver installation; see the September 18 investigation above.
  - Contents applied from Linux: split-WIM image via `wimlib`, 41 Surface runtime driver packages (battery/serial-hub/HID/UCSI/Wi-Fi/Chipset), answer file with local `SurfaceTest` account, internal-disks-offline SAN policy, portable-OS registry flags, hibernation/BitLocker/encryption guards, Windows-Update driver exclusion, and a 60-second dual-battery capture tool on the Public Desktop.
  - The `bcdboot` step ran in an isolated VM (Lexar as the only physical disk, a scratch log image, original Microsoft ISO, no network) through typed diskpart/bcdboot commands with screenshot confirmation. Abandoned the custom-WinPE ISO after six smoke tests: ISO9660-only builds stalled, `-boot-info-table` corrupted `etfsboot.com`, and the UDF rebuild did not complete a successful smoke test. No firmware flashed; internal SSD excluded from the VM, with `SanPolicy=4` configured for native Windows.
  - Extra tools installed via interactive terminal with user approval: `hivex 1.3.24-8.1`, `ntfs-3g 2026.7.7-1.1`, `fuse2 2.9.9-6`, `cdrtools 3.02a09-6.1` (Snapper snapshots 31–34).
- **Automatic Display Scale & Text-Size Calibration (`core`, 2026-09-17)**:
  - Created `core/.local/bin/hypr-autoscale` (symlinked to `~/.local/bin/hypr-autoscale`): Profile-aware and EDID-driven auto-calibrator that automatically detects display pixel density (PPI) and applies the ideal Omarchy-style text scaling.
  - High-DPI / Retina screens (PPI >= 200, `surface`, `macbook-t2`): sets text size 12px (Terminal 9.0pt, UI scale 1.00x).
  - Medium High-DPI screens (150 <= PPI < 200, 27" 4K): sets text size 13px (Terminal 10.0pt).
  - Standard DPI screens (PPI < 150, 1080p/1440p, `desktop`, generic `laptop`): sets text size 14px (Terminal 11.0pt, UI scale 1.17x).
  - Wired into `install.sh` Step 4/4 Post-Install Setup to guarantee "it just works" out of the box on clean installs across different hardware.
  - Added `--follow-symlinks` to `hypr-text-size` sed commands to prevent breaking GNU Stow symlinks into detached local files.
- **Omarchy-Aligned Capture & OCR Suite (`core`, 2026-09-17)**:
  - Installed `tesseract 5.5.3-1.1`, `tesseract-data-eng 4.1.0-5`, and `wf-recorder 0.6.0-2.1` via pacman through interactive Kitty/Hyprland terminal.
  - Created `core/.local/bin/hypr-screenshot` (symlinked to `~/.local/bin/hypr-screenshot`): Smart screenshot tool feeding active window and monitor geometry candidate boxes to `slurp`. Enables single-click snapping to any hovered window, single-click to capture desktop, or click-and-drag for freeform region; pipes directly into Satty annotation editor with default save path `~/Pictures/Screenshots/`. Also supports `active` window and `fullscreen` flags.
  - Created `core/.local/bin/hypr-ocr` (symlinked to `~/.local/bin/hypr-ocr`): Region / window text extraction tool using `grim` + `slurp` + `tesseract -l eng` piped into `wl-copy` with instant notification.
  - Created `core/.local/bin/hypr-record` (symlinked to `~/.local/bin/hypr-record`): Lightweight toggle screen recorder via `wf-recorder` (30fps, geometry selection, auto-saving to `~/Videos/Captures/`).
  - Created `core/.local/bin/hypr-capture-menu` (symlinked to `~/.local/bin/hypr-capture-menu`): Interactive floating capture selector launched via `fzf` in dedicated `--class CaptureMenu` Kitty popup.
  - Added floating window rule for `CaptureMenu` in `core/.config/hypr/config/windowrules.lua`.
  - Registered full Omarchy-aligned keybindings in `core/.config/hypr/config/binds.lua`:
    - `Print` / `SUPER + SHIFT + S` -> Smart Screenshot (Window click / Region drag)
    - `SHIFT + Print` -> Active Window Screenshot (instant)
    - `CONTROL + Print` -> Fullscreen Screenshot
    - `SUPER + Print` / `SUPER + SHIFT + P` -> Color Picker (`hyprpicker -a`)
    - `ALT + Print` / `SUPER + ALT + SHIFT + S` -> Screen Recording Toggle
    - `SUPER + CONTROL + Print` / `SUPER + CONTROL + SHIFT + S` -> OCR Text Extraction
    - `SUPER + CONTROL + C` -> Interactive Capture Menu
  - Validated clean Hyprland IPC reload with 0 config errors (`hyprctl configerrors`). Updated `references/keybindings.md`.
- **Portable Windows diagnostic USB preparation tooling (`surface`, 2026-09-17)**:
  - User authorized preparing the 128 GB-class Lexar USB after moving it to USB-A. Installed `qemu-system-x86 11.1.1-2`, `wimlib 1.14.5-3.1`, `msitools 0.106-3.1`, and `libisoburn 1.5.8.2-1.1` (xorriso provider), plus dependencies including `edk2-ovmf 202608-1` and `ntfsprogs 2026.7.7-1.1`. Pacman completed successfully through an interactive Kitty terminal; Snapper snapshots 27/28.
  - Downloaded Windows 11 Enterprise Evaluation 25H2 x64 from Microsoft's Evaluation Center; SHA-256 matches its official verification PDF (`a61adeab895ef5a4db436e0a7011c92a2ff17bb0357f58b13bbc4062e535e7b9`). Downloaded the full official Surface Book 3 MSI for driver staging, following the earlier range-only CFU investigation.
  - Assembled 41 runtime driver INFs (92.56 MiB) including the Surface battery/serial-hub/HID/UCSI stack; selected files checked against MSI sizes and available hashes. Working artifacts are under `~/.cache/opencode/surface-windows-usb/`; `/tmp` is RAM-backed and unsuitable for the 6.60 GiB ISO.
- **Right-Click / Menu Key Dual-Role Super Modifier (`core`, 2026-09-17)**:
  - Enabled native XKB option `altwin:menu_win` in [`~/.config/hypr/config/inputs.lua`](file:///home/jmvp/.config/hypr/config/inputs.lua) (synced to `dotfiles/core/`), mapping the physical Context Menu (Right-Click) key to `Super_R`.
  - Added clean-tap release binding in [`~/.config/hypr/config/binds.lua`](file:///home/jmvp/.config/hypr/config/binds.lua) (`SUPER + SUPER_R`, `release = true`) to dispatch native `Menu` event to the active window via `hl.dsp.send_shortcut`, opening the right-click context menu when tapped alone.
  - When held or chorded (e.g., `Right-Click Key + Return`), engages `SUPER` modifier to open Kitty or trigger any Hyprland Super shortcuts; chord consumption prevents the context menu from opening upon key release.
  - Updated [`~/.local/bin/hypr-toggle-altwin`](file:///home/jmvp/.local/bin/hypr-toggle-altwin) to preserve `altwin:menu_win` when toggling between PC layout (`altwin:menu_win`) and Mac layout (`altwin:swap_lalt_lwin,altwin:menu_win`).
  - Completely native implementation: zero new packages, zero background daemons, zero sudo elevation required.
- **Noctalia Bar Caffeine Widget (`core`, 2026-09-17)**:
  - Added native `caffeine` widget to the top bar center lane (`center = [ "caffeine", "workspaces", "spacer_1", "active_window" ]`) positioned immediately to the left of the workspace pills.
  - Configured widget theme styling in `~/.config/noctalia/config.toml` (and synced to `core/.config/noctalia/config.toml`) with `color = "secondary"`.
  - Enables one-click toggling of Wayland idle inhibitor directly from the bar (with active/inactive steaming cup icon states), complementing the existing `SUPER + CTRL + I` keyboard shortcut.
  - Validated with `noctalia config validate` and cleanly restarted Noctalia daemon via Hyprland IPC.
- **On-Screen Touch Virtual Keyboard (`wvkbd`) (`surface`, 2026-09-17)**:
  - Installed `wvkbd 0.20-1` (and `scdoc 1.11.5-1.1`) via AUR (`yay`) through interactive Kitty/Hyprland prompt per Rule 8.
  - Created executable toggle wrapper [`core/.local/bin/hypr-virtual-keyboard`](file:///home/jmvp/dotfiles/core/.local/bin/hypr-virtual-keyboard) (symlinked to `~/.local/bin/hypr-virtual-keyboard`) using `pkill -RTMIN -x wvkbd-mobintl` for instantaneous zero-latency overlay toggling.
  - Calibrated height for Surface Book 3 3000x2000 @ 2x scaling (`-L 320 -H 320`) to dock neatly at the bottom 32% of the screen.
  - Tracked `wvkbd` in [`profiles/surface/packages.txt`](file:///home/jmvp/dotfiles/profiles/surface/packages.txt).
  - Documented complete architecture, IME vs OSK distinction, and troubleshooting in [`profiles/surface/gotchas/virtual-keyboard.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/virtual-keyboard.md) (symlinked to `references/gotchas/virtual-keyboard.md`).
- **XH Multi-Page Media Hub WebApp (`core`, 2026-09-17)**:
  - Ported `xh-launch` Python launcher, `XH.desktop`, and `XH.png` from `omarchy-dots` to `core/`.
  - Installed launcher to `~/.local/bin/xh-launch`, desktop entry to `~/.local/share/applications/XH.desktop`, and icons to `~/.local/share/icons/`.
  - Configured to launch Brave (`brave-origin`) in container mode (`~/.config/brave-webapps/containers/diagnostics`) with automatic Hyprland group/tab window merging.
- **Smart Tiered Sleep (`suspend-then-hibernate`) (`surface`, 2026-09-17)**:
  - Configured modular systemd drop-in `/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf`: enabled `AllowSuspendThenHibernate=yes`, set `HibernateDelaySec=90min`, and set `HibernateOnACPower=no`.
  - Configured modular systemd logind drop-in `/etc/systemd/logind.conf.d/10-lid-sleep.conf`: set `HandleLidSwitch=suspend-then-hibernate` on battery and `HandleLidSwitchExternalPower=suspend` on AC charger. Reloaded `systemd-logind` safely via SIGHUP.
  - Updated `~/.config/hypr/hypridle.conf` 15-minute inactivity trigger to invoke `systemctl suspend-then-hibernate` and restarted `hypridle`.
  - Result: The laptop retains instant <0.5s `s2idle` wake for daytime breaks under 90 minutes (~1.8% battery loss), but automatically enters zero-watt NVMe hibernation for overnight or extended storage, eliminating the ~20% overnight drain.
- **Firmware diagnostic tooling (`surface`, 2026-09-17)**:
  - Installed user-approved `fwupd 2.1.7-1.1`, plus dependencies `fwupd-efi 1.8-2` and `passim 0.1.12-1.1`, with `sudo pacman -S --needed fwupd` through interactive Kitty/Hyprland. Pacman completed successfully and created Snapper snapshots 19/20.
  - Verified package versions, firmware/device enumeration, LVFS metadata refresh, and update query. `fwupd.service` D-Bus-activated successfully; `fwupd-refresh.timer` is disabled. `hyprctl configerrors` clean. Updated installed-package reference and Surface charging gotchas.
- **Firmware reverse-engineering tooling (`surface`, 2026-09-17)**:
  - Installed user-approved `cabextract 1.11-3.1` (`sudo pacman -S --needed cabextract`, 0.10 MiB installed, Snapper snapshots 21/22) after `bsdtar` proved unable to decompress Microsoft's LZX-21 CAB folders.
  - Used bounded HTTP range reads against the official MSI to extract and MSI-hash-verify five small base files (PD `.cfu`/`.offer.bin`, two KIP `.offer.bin`, two `.cat`) without downloading the 1.67 GB bundle. No firmware flashed.
- **Universal Zen Browser keybinding synchronization (`core`, 2026-09-17)**:
  - Saved canonical keybindings template to `core/.local/share/zen/zen-keyboard-shortcuts.json` (stowed to `~/.local/share/zen/`).
  - Created executable sync utility `core/.local/bin/zen-keybinds-sync` (stowed to `~/.local/bin/zen-keybinds-sync`): supports `--status`, `--apply` (with auto-detection across all active profiles, running-process safety check, and automatic pre-seeding of fresh profiles), and `--export`.
  - Wired automated keybinding synchronization into universal post-install setup (Step 4/4) in `install.sh`. Tested and verified via `install.sh --dry-run`.
### Changed
- **Zen Browser Tab vs. Workspace Shortcut Collision (`surface`, 2026-09-17)**:
  - **Issue**: Both browser tab selection (`key_selectTab1`..`8`, `key_selectLastTab`) and Zen workspace switching (`zen-workspace-switch-1`..`10`) defaulted to `accel: true` (<kbd>Ctrl</kbd> + <kbd>1..9</kbd>) on Linux, causing keyboard shortcut collision inside Zen Browser.
  - **Fix**: Re-mapped tab switching to <kbd>Alt</kbd> + <kbd>1..9</kbd> (`modifiers.alt = true`, `modifiers.accel = false`) in `~/.config/zen/1q66wgda.Default (release)/zen-keyboard-shortcuts.json` while Zen was closed. Zen workspace switching retained on <kbd>Ctrl</kbd> + <kbd>1..9</kbd>, <kbd>0</kbd>. Backed up original to `zen-keyboard-shortcuts.json.bak`.
  - **Documentation**: Documented modifier mappings, CLI manipulation via `jq`/Python, and in-memory reload gotchas in `references/gotchas/zen-browser.md`.
- **OpenCode pacman -> curl installer (`surface`)**:
  - Removed `opencode 2.0.3-1.1` from `cachyos-extra-v4` via `sudo pacman -Rns opencode` (interactive Kitty `hl.exec_cmd` prompt per Rule 8).
  - Installed upstream `v2.0.5` via `curl -fsSL https://opencode.ai/v2/install | bash` to `~/.opencode/bin/opencode`; installer appended `fish_add_path /home/jmvp/.opencode/bin` to `core/.config/fish/config.fish` (stowed, no overwrite).
  - Verified: `which opencode` -> `~/.opencode/bin/opencode`, `opencode --version` -> `v2.0.5`, `opencode upgrade` -> `Using method: curl`, `already installed` (fixes `installation method not found`).
  - Note: `cachyos-extra`/`AUR` builds are unsupported for self-update; keep `packages.txt` free of `opencode` to avoid shadowing `/usr/bin/opencode` over `~/.opencode/bin`.
  - Symlinked `~/.local/bin/opencode` -> `~/.opencode/bin/opencode` for bash/non-fish `PATH` fluency (fish uses `fish_add_path`, bash uses `~/.local/bin`); verified `opencode upgrade` in both shells.
### Fixed
- **Brave / WebApps GNOME Keyring Prompt (`core`, 2026-09-19)**:
  - **Issue**: Launching `xh-launch` or webapps (`YouTube.desktop`, `AllAnime.desktop`, `Hanime.desktop`, `PH.desktop`) caused `gnome-keyring` to spawn `gcr-prompter` ("Unlock Keyring" for Default keyring) because `greetd` does not unlock gnome-keyring on login.
  - **Fix**: Created [`core/.config/brave-origin-flags.conf`](file:///home/jmvp/dotfiles/core/.config/brave-origin-flags.conf) with `--password-store=basic` (symlinked to `~/.config/brave-origin-flags.conf` and `~/.config/brave-flags.conf`) so all Brave launches automatically inherit basic storage. Also updated all webapp desktop files in [`core/.local/share/applications/`](file:///home/jmvp/dotfiles/core/.local/share/applications/) and [`core/.local/bin/xh-launch`](file:///home/jmvp/dotfiles/core/.local/bin/xh-launch). Stopped active `gcr-prompter` service.
- **Fcitx5 vs. On-Screen Virtual Keyboard Architectural Misconception & Binding (`surface`, 2026-09-17)**:
  - **Issue**: User reported "Fcitx5 for virtual keyboard is not working" when attempting on-screen typing on Surface Book 3 in tablet mode or via `SUPER + ALT + V`.
  - **Root Cause**: Twofold: (1) `fcitx5` was not installed on the system (`which: no fcitx5`), causing Hyprland's execution of `fcitx5-remote -t` to fail with command not found; (2) Fcitx5 is an Input Method Editor (IME) for CJK multi-byte keystroke composition, not a graphical on-screen touch keyboard (OSK). `fcitx5-remote -t` only toggles IME conversion state, never rendering a touch keyboard UI on Wayland.
  - **Fix**: Replaced broken `fcitx5-remote -t` shortcut in `profiles/surface/.config/hypr/config/profile/binds.lua` with dedicated `hypr-virtual-keyboard` wrapper targeting `wvkbd-mobintl` via native compositor dispatcher `hl.dsp.exec_cmd(...)`. Passing native dispatcher bypasses `helpers.lua`'s default `uwsm-app -- ` string-wrapping prefix, avoiding `uwsm_app-daemon` PATH lookup failures caused by systemd user sessions omitting `~/.local/bin`. Deployed `core/.config/environment.d/10-path.conf` to guarantee `~/.local/bin` in systemd user PATH.
  - **Verification**: Flushed stale Lua bind callbacks via `hl.unbind`; re-evaluated bind table (`arg: 14`); `hyprctl configerrors` 0 errors; tested live process spawning with `nohup` and signal-based toggling (`pkill -RTMIN`) directly over Wayland Layer 3 overlay.
- **Surface Book 300% battery percentage calculation desync (`surface`, UPower)**:
  - **Issue**: Noctalia status bar and `upower DisplayDevice` reported impossible `299.032%` (~300%) battery level while discharging normally.
  - **Root Cause**: Surface Book base battery (`BAT2`, 45.3 Wh) suffered transient EC communication timeout (`power_supply BAT2: driver failed to report 'present' property: -110`). UPower's `up_device_battery_update_info()` cleared D-Bus property `energy-full` to 0 but failed to clear internal comparison cache `priv->energy_full_reported`. Upon battery recovery, UPower skipped updating D-Bus `energy-full`. Composite `DisplayDevice` summed total energy from both batteries (43.27 Wh) but divided only by tablet battery `BAT1` capacity (14.47 Wh), yielding ~300% (upstream UPower issue #336).
  - **Fix**: Restarted UPower service via interactive Kitty prompt per Rule 8 (`sudo systemctl restart upower`), restoring correct `DisplayDevice` capacity (59.79 Wh) and percentage (~70.2%).
  - **Documentation**: Documented full architecture and recovery procedures in `profiles/surface/gotchas/battery-upower.md` (symlinked into skill `references/gotchas/battery-upower.md`).
- **Fastfetch terminal greeting cleanup and alignment (`core/.local/bin/fastfetch-custom`, `surface`)**:
  - **Mini Logo Alignment**: Stripped raw DMI/SKU string from `Host`, restoring clean `Surface Book 3` and preventing line width blowout that shoved the mini CachyOS logo to column 89+.
  - **Window Manager**: Added support for fastfetch's `Window Manager:` key alongside `WM:`, fixing blank `WM: ` to properly display `Hyprland 0.56.2`.
  - **GPU Tagging**: Differentiated integrated (`iGPU`) from discrete (`dGPU`) graphics; Intel Iris Plus Graphics G7 is now accurately tagged as `(iGPU)` instead of forcing `(dGPU)`.
  - **Audio Detection**: Replaced hardcoded `"Apple Audio (aaudio)"` with dynamic fastfetch `Sound` detection (`Built-in Audio Analog Stereo`), retaining Apple Audio fallback only on Apple hardware DMI.
  - **Icons Fallback**: Added GSettings fallback for `Icons` (`Adwaita`) when fastfetch detects no icon theme from GTK configs.
  - **Dual Battery Support**: Added combined dual battery calculation for Surface devices (`80% (79% Tab / 82% Base) [Discharging]`).
  - **Aligned Columns**: Made bottom spec table divider (`│`) calculate column width dynamically to prevent misalignment across varying metric lengths.
- **Fish duplicate `.local/bin` PATH (`core/.config/fish/config.fish`, `surface`)**: removed `set -gx PATH "/home/jmvp/.local/bin" $PATH` added by Antigravity CLI installer; kept canonical `fish_add_path "$HOME/.local/bin"` (avoids duplicate entries in `fish_user_paths`).
- **Omarchy-style display scaling (`surface`)**: terminal/shell felt oversized from stacked scaling (compositor `x2` × Noctalia `ui_scale 1.2` × `bar scale 1.1` × large terminal fonts), while Omarchy keeps compositor at 2x and scales text with one knob.
  - `profiles/surface/.../profile/monitors.lua`: `eDP-1` mode pinned `3000x2000@60` -> `preferred` (kept `scale 2`, `GDK_SCALE 2` — correct for 267 PPI); added commented Omarchy-style `1.6/1.75` (4K) and `1/1` (1080p/1440p) alternatives.
  - New `core/.local/bin/hypr-monitor-scale up|down`: cycles focused monitor through `1, 1.25, 1.6, 2, 3, 4` at runtime (Omarchy `Super+/` equivalent; reboot restores profile default).
  - `core/.config/hypr/config/binds.lua`: `Super+slash` / `Super+Alt+slash` wired to the stepper.
  - Unified text sizes: kitty `font_size 11.0`, `window_padding_width 25->14`; alacritty `size 12.0->11.0`; Noctalia `ui_scale 1.20->1.0`, `bar scale 1.10->1.0`.
  - New `core/.local/bin/hypr-text-size [size|reset]` — same-as-Omarchy one knob (`12px -> 9pt terminal`, `pt = round(px*9/12)`): writes kitty (`USR1` live-reload) + alacritty + ghostty/foot if present, Noctalia `ui_scale = px/12` + `config-reload`, GTK `text-scaling-factor` (quantized). Baseline applied: `hypr-text-size 12` (kitty/alacritty now 9pt, `ui_scale 1.00`, GTK `1.0`).
  - Verified: `hyprctl reload` + `hyprctl configerrors` clean, `eDP-1 scale 2` steady, `noctalia msg config-reload` OK (note: skill's `msg reload` is stale — correct cmd on 5.1.0 is `config-reload`). New terminals pick up font sizes on open; kitty live-reloads via `USR1`.

## [2.37.0] - 2026-09-16
### Changed
- **OpenCode v1.18.31 -> v2.0.3 (`surface`, `pacman`)**:
  - Installed `opencode 2.0.3-1.1` from `cachyos-extra-v4` via `sudo pacman -S opencode` (explicit install, ~197M). Deps satisfied: `curl glibc icu ripgrep tar`, `wl-clipboard` already present.
  - Removed shadowing v1 curl-install binary `~/.opencode/bin/opencode` (backed up to `~/opencode-v1-backup-20260916.tar.gz` + `~/.config/opencode/opencode.jsonc.v1.bak`); removed empty `~/.opencode/bin/` and the `# Opencode path` `fish_add_path` block from `~/.config/fish/config.fish`; cleared stale `~/.opencode/bin` from universal `fish_user_paths`.
  - Verified: `which opencode` -> `/usr/bin/opencode`, `opencode --version` -> `v2.0.3`, `opencode --help` OK.
  - Note: V1/V2 share the `opencode` command (no side-by-side); `opencode.jsonc` kept as-is (minimal `$schema`-only, V2 reads V1 shape in-memory); first TUI start will auto-create `~/.config/opencode/cli.json` from old `tui.json` if present. Breaking changes to port later: plugin API, server API, permissions/tools schema (see v2 migrate guide).

## [2.36.0] - 2026-09-16
### Fixed
- **Noctalia wallpaper panel slow every open — true root cause (`surface`, Noctalia 5.1.0)**:
  - **Supersedes 2.35.0 (retracted)**: the `stat()` mtime theory was wrong. Re-verified against upstream `noctalia-shell` source (`src/render/core/thumbnail_service.cpp`): disk key = FNV-1a of `path + "\n" + file_size + "\n" + last_write_time.ticks + "\n" + targetPx + "\nthumbnail-service-v2"` — i.e. `fs::last_write_time` ticks, exactly what the ORIGINAL pre-cacher used. Proof: 163 `fileclock@428` hits vs 0 `stat@428` hits in live cache.
  - **Real bug #1 — wrong width**: `WallpaperTile::thumbnailTargetPx()` requests the tile's PHYSICAL display size (`lround(max(cellW,cellH) * renderScale)`), so width is per-machine/per-layout, not fixed 361. Measured on `surface` (eDP-1 scale 2, ui_scale 1.2): grid tiles = **428px** (MacBook-T2 Retina = 361 — which is why the macbook-t2 solution worked there). All 1637 `stat@361` files from 2.35.0 were orphans Noctalia never requests here — deleted (freed ~19M).
  - **Real bug #2 — one width is not enough**: secondary views request **451px** (87 files) and **541px** (24 files) variants of the same wallpapers.
  - **Fix**: pre-cacher default width `361 -> 428`, `vipsthumbnail` geometry `--size Wx` -> box `--size WxW` (matches Noctalia long-edge downscale for portraits), `cachy-sync-wallpapers` now warms `428 451 541 361` (overridable via `NOCTALIA_THUMB_WIDTHS`, covers both machines).
  - **Warmed `surface` cache**: 1452 + 1550 + 1613 jobs (~7 min total, 8 threads), cache now 4914 files / 73M. Live 12s panel-open test: **27 misses -> 1** (single 990px header preview, now cached). Grid renders instantly.
  - Only 2–4 Noctalia decode workers serve misses, so any future miss (new wallpapers, layout change) still stutters briefly — re-run `cachy-sync-wallpapers` after pulls or panel/resolution changes.

## [2.35.0] - 2026-09-16 (RETRACTED — see 2.36.0)
### Fixed
- **Noctalia pre-cacher mtime hash mismatch (`core/.local/bin/noctalia-precache-wallpapers.cpp`)**:
  - **Issue**: Pre-cacher used `fs::last_write_time(p).time_since_epoch().count()` for the thumbnail hash key, but `file_clock` epoch is implementation-defined (observed negative counts on libstdc++), while Noctalia keys on Unix `mtime_nanos` (`stat st_mtim`). Generated thumbnails never hit — cache stayed cold (114 files / 2.1M for 1637 wallpapers on `surface`).
  - **Fix**: Switched to `stat()` (`st_mtime * 1e9 + st_mtim.tv_nsec`), matching Noctalia's `path + "\n" + size + "\n" + mtime_nanos + "\n361\nthumbnail-service-v2"` FNV-1a key. Verified stat-hash exists post-run.
  - **Warmed `surface` cache**: full run `noctalia-precache-wallpapers ~/Pictures/Wallpapers` — 1637 stills (989 jpg + 555 png + 72 jpeg + 21 webp), 1613 jobs in 135.3s on 8 threads, cache now 1751 files / 21M with 1637/1637 hits on re-run. Wallpaper panel (`ALT+Space`) grid now renders instantly.
  - Deleted 24 wrong-hash thumbnails generated during validation before the fix.
  - **RETRACTION**: self-consistency checks ("already cached") only proved the tool agreed with itself, not with Noctalia. The `stat()` files were orphans (deleted in 2.36.0). Lesson: always verify with a live Noctalia open (new-file count) and against upstream source.

## [2.34.0] - 2026-09-15
### Added
- **Native Window Grouping / Stacking Keybindings (`core/.config/hypr/config/binds.lua`)**:
  - Implemented Hyprland native window grouping and tabbed stacking matching Omarchy muscle memory:
    - **Toggle Group / Stacking (`SUPER + G`)**: Toggles the active window into a group or merges/unmerges it with adjacent groups via native Lua dispatcher `hl.dsp.group.toggle()`.
    - **Move Window Out of Group (`SUPER + ALT + G`)**: Explicitly extracts the focused window from a tabbed group stack into regular tiled layout (`hl.dsp.exec_raw("moveoutofgroup", "")`).
    - **Cycle Window in Group (`SUPER + ALT + Tab` / `SUPER + ALT + SHIFT + Tab`)**: Cycles forward and backward through tabs within the active group stack (`hl.dsp.group.next()` and `hl.dsp.group.prev()`).
    - **Toggle Group Lock (`SUPER + CONTROL + G`)**: Toggles group lock state (`hl.dsp.group.lock_active()`) to prevent auto-swallowing or accidental group merging.
  - Leverages pre-configured CachyOS groupbar theming (`CACHYLBLUE` / `CACHYLGREEN` in `decorations.lua`).
  - Registered all 5 bindings with live IPC metadata descriptions, exposing them to the interactive cheatsheet (`SUPER + K`).
  - Updated [`references/keybindings.md`](references/keybindings.md) with complete group management shortcuts.

## [2.33.0] - 2026-09-15
### Fixed
- **Diagnosed Post-Update Keyboard Inoperability & Linux 7.2.5 T2 Driver Regression**:
  - **Issue**: Internal Apple keyboard, trackpad, Touch Bar, and audio stopped functioning after upgrading from `linux-cachyos 7.2.3-1` to `7.2.5-1`.
  - **Root Cause**: Upstream CachyOS removed the `7.2/t2` branch in the `7.2.5-1` release, omitting the staging `t2bce` drivers (`t2bce_core`, `t2bce_vhci`, `t2bce_dma`, `t2bce_audio`). Without `t2bce_vhci`, the virtual USB host controller (Bus 7) failed to enumerate, leaving the internal keyboard and input devices disconnected.
  - **Resolution**: Created turnkey rollback script [`cachy-downgrade-kernel-723`](file:///home/java1127/.local/bin/cachy-downgrade-kernel-723) to reinstall `linux-cachyos-7.2.3-1`, `linux-cachyos-headers-7.2.3-1`, and `linux-cachyos-nvidia-open-7.2.3-1` from local cache, pin them in `/etc/pacman.conf` (`IgnorePkg`), regenerate boot entries, and reboot cleanly. Staged in `profiles/macbook-t2/scripts/cachy-downgrade-kernel-723.sh`.
  - Documented complete troubleshooting procedure in `references/gotchas/apple-t2.md` (Section 9).

## [2.32.0] - 2026-09-15
### Added
- **Combined Directional Cross-Monitor Architecture (`core/.config/hypr/config/binds.lua`)**:
  - Implemented symmetrical directional cross-monitor dispatchers:
    - **Directional Window to Monitor (`SUPER + SHIFT + ALT + Arrows`)**: Moves the focused window to the Left / Right / Top / Bottom adjacent monitor (`hl.dsp.window.move({ monitor = "l/r/u/d" })`).
    - **Directional Workspace to Monitor (`SUPER + CONTROL + ALT + Arrows`)**: Moves the active workspace and all its tiled windows to the Left / Right / Top / Bottom adjacent monitor (`hl.dsp.workspace.move({ monitor = "l/r/u/d" })`).
  - Upgraded single-key monitor cycle bindings to native Lua API:
    - `SUPER + grave (~)`: Focus next monitor (`hl.dsp.focus({ monitor = "+1" })`).
    - `SUPER + SHIFT + grave`: Move active window to next monitor (`hl.dsp.window.move({ monitor = "+1" })`).
    - `SUPER + CONTROL + grave`: Move active workspace to next monitor (`hl.dsp.workspace.move({ monitor = "+1" })`).
  - Updated keybindings reference and registered all 8 new bindings with live IPC descriptions (`SUPER + K`).

## [2.31.0] - 2026-09-15
### Added
- **Turnkey Multi-PC Wallpaper Synchronization (`cachy-sync-wallpapers`, `core/packages.txt`)**:
  - Added `gcc` and `libvips` to [`core/packages.txt`](file:///home/java1127/dotfiles/core/packages.txt), ensuring both the C++20 compiler and `vipsthumbnail` engine are automatically installed by `install.sh` on any fresh CachyOS/Arch device.
  - Enhanced [`cachy-sync-wallpapers`](file:///home/java1127/dotfiles/core/.local/bin/cachy-sync-wallpapers) with robust multi-path source candidate discovery for `noctalia-precache-wallpapers.cpp`.
  - Added automated state initialization in `cachy-sync-wallpapers` to seed `~/.local/state/noctalia/state.toml` with `flatten = true` and `sort = "random"` out of the box on first boot.

## [2.30.0] - 2026-09-15
### Added
- **Native Directional Window Swapping (`CTRL + SHIFT + Arrows`)**:
  - Implemented `CTRL + SHIFT + Left/Right/Up/Down` in `core/.config/hypr/config/binds.lua` matching Omarchy muscle memory.
  - Upgraded window swapping dispatchers from external subshell commands (`hyprctl dispatch swapwindow`) to native compositor API `hl.dsp.window.swap({ direction = ... })` for instantaneous, zero-latency execution.
  - Preserved `SUPER + ALT + Arrows` as alternative layout-agnostic binding.
  - Registered descriptions in Hyprland's internal table, exposing them to `SUPER + K` live IPC search.

## [2.29.0] - 2026-09-15
### Changed
- **Microsoft Surface Profile Modernization & Omarchy Cleanup (`profiles/surface/`)**:
  - Reset `profiles/surface` to a lean, minimal CachyOS baseline:
    - **Package Source**: Updated `packages.txt` with official binary repository package names (`linux-surface`, `linux-surface-headers`, `iptsd`, `surface-dtx-daemon`, `surface-control`).
    - **Automated Repository Setup (`pre-install.sh`)**: Created profile pre-install hook to automatically import the official Surface signing key (`56C464BAAC421453`) and configure `[linux-surface]` (`https://pkg.surfacelinux.org/arch/`) in `/etc/pacman.conf` prior to package synchronization.
    - **Precision Touchpad Calibration (`inputs.lua`)**: Configured `scroll_factor = 0.4` and `disable_while_typing = false` to eliminate hyperactive trackpad scrolling under Hyprland.
    - **Hardware Keybindings (`binds.lua`)**: Implemented native Surface shortcuts via `helpers.bind`:
      - `SUPER + ALT + D`: Requests tablet base detachment (`surface dtx request`) with desktop notification.
      - `SUPER + ALT + V`: Toggles on-screen virtual keyboard panel (`fcitx5-remote -t`).
    - **Bootloader & Services (`setup.sh`)**: Automated enabling of `surface-dtx-daemon.service` and `iptsd.service`, and configured `/etc/limine-entry-tool.d/zz-surface-kernel.conf` to prioritize `linux-surface` as default boot entry.
    - **Omarchy Bloat Removal**: Wiped 5 legacy Omarchy gotchas and obsolete `services.txt`, leaving an empty `gotchas/` folder ready for fresh CachyOS documentation.
- **Installer Hook Architecture (`install.sh`)**:
  - Added profile `pre-install.sh` lifecycle hook executed before package manager synchronization.
  - Added `--ignore=^pre-install\.sh$` to GNU Stow deployment flags.

## [2.28.0] - 2026-09-15
### Added
- **Native Noctalia Wallpaper Panel Acceleration & Multi-threaded Pre-cacher (`noctalia-precache-wallpapers`)**:
  - Reverse-engineered Noctalia v5's internal thumbnail caching engine: discovered 64-bit FNV-1a hash key `path + "\n" + file_size + "\n" + mtime_nanos + "\n361\nthumbnail-service-v2"` stored as 16-hex WebP files in `~/.cache/noctalia/thumbnails/`.
  - Created high-performance C++ utility [`noctalia-precache-wallpapers`](file:///home/java1127/dotfiles/core/.local/bin/noctalia-precache-wallpapers) utilizing `vipsthumbnail` across all 16 hardware threads. Batch-cached all 1,410 remaining wallpapers in 30.9 seconds (1,659 total thumbnails in cache).
  - Integrated `noctalia-precache-wallpapers` into [`cachy-sync-wallpapers`](file:///home/java1127/dotfiles/core/.local/bin/cachy-sync-wallpapers) to automatically pre-cache newly downloaded wallpapers.
  - Configured Noctalia's native Random Shuffle mode in `~/.local/state/noctalia/state.toml` (`sort = "random"` and `flatten = true`).
  - Remapped **`ALT + Space`** in [`binds.lua`](file:///home/java1127/dotfiles/core/.config/hypr/config/binds.lua#L142) from `waypaper` to Noctalia's native wallpaper panel (`noctalia msg panel-toggle wallpaper`), providing instantaneous startup, zero CPU decode lag, and locked 60 FPS scrolling.

### Removed
- **Legacy Waypaper & Hyprpaper Wallpaper Architecture**:
  - Terminated running `hyprpaper` process that was occluding Noctalia's native wallpaper layer on Wayland layer 0.
  - Deleted obsolete `~/.cache/waypaper` (67 MB) and `~/.local/share/waypaper` (28 MB venv/repo).
  - Cleaned up stowed configuration `~/dotfiles/core/.config/waypaper/` and `~/.config/waypaper/`.
  - Removed floating window rule for Waypaper in [`windowrules.lua`](file:///home/java1127/dotfiles/core/.config/hypr/config/windowrules.lua).
  - Removed `waypaper` and `hyprpaper` from [`core/packages.txt`](file:///home/java1127/dotfiles/core/packages.txt) and launched interactive Kitty prompt for pacman removal.
  - Updated [`AGENTS.md`](file:///home/java1127/dotfiles/AGENTS.md) and [`references/current-state.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/current-state.md).

## [2.27.0] - 2026-09-15
### Added
- **Boot-Time AMDGPU & PCIe ASPM Power Optimization Service (`amdgpu-power-setup.service`)**:
  - Created [`amdgpu-power-setup.service`](file:///home/java1127/dotfiles/profiles/macbook-t2/scripts/amdgpu-power-setup.service) to automatically enforce `powersupersave` PCIe Active State Power Management and AMD GPU `POWER_SAVING` profile on boot.
  - Updated [`profiles/macbook-t2/setup.sh`](file:///home/java1127/dotfiles/profiles/macbook-t2/setup.sh) to deploy, enable, and start `amdgpu-power-setup.service`.
  - Created [`apply-power-optimizations-and-upgrade`](file:///home/java1127/.local/bin/apply-power-optimizations-and-upgrade) helper script to automate setup and launch package upgrade interactively in Kitty via Hyprland IPC.

### Fixed
- **Hung Background Process & Power Leak Prevention**:
  - Terminated hung `git-remote-https` process (PID 27045) running continuously in a tight loop since Sep 14, restoring deeper Intel CPU package sleep states (C8–C10).
  - Powered down inactive Bluetooth controller (`bluetoothctl power off`), reducing idle radio power draw.

## [2.26.0] - 2026-09-15
### Added
- **Fresh Install Package Completeness Synchronization (`core/packages.txt`)**:
  - Added 8 missing runtime dependencies to `core/packages.txt` to guarantee 100% turnkey deployment on fresh CachyOS/Arch installations:
    - `uwsm`: Session manager backend providing `uwsm-app --` cgroups wrapping for all application launchers.
    - `brightnessctl`: Hardware controller for screen/keyboard brightness keys and `hypridle` inactivity dimming.
    - `fzf`: Interactive fuzzy selector backend for `SUPER + K` (`hypr-keybinds-menu`).
    - `hyprpicker`: Color picker tool for `SUPER + SHIFT + P`.
    - `lazydocker`: Container management TUI for `SUPER + SHIFT + D`.
    - `brave-origin-bin`: Underlying browser engine for all custom WebApp desktop launchers (YouTube, AllAnime, etc.).
    - `cliamp-bin` & `yt-dlp`: Retro terminal audio player and streaming backend.
    - `xorg-xhost`: Root authorization helper for XWayland applications invoked in `autostart.lua`.

### Changed
- **Decoupled Dynamic Wallpaper Rotation State (`waypaper`)**:
  - Enabled `use_xdg_state = True` in `core/.config/waypaper/config.ini`, storing dynamic wallpaper selection in `~/.local/state/waypaper/state.ini` to prevent hourly git working tree modifications.
- **Synchronized Active Color Palettes & Restored Theme Symlinks**:
  - Synchronized latest active Material 3 wallpaper palette across Alacritty, Btop, and Kitty.
  - Re-linked `~/.config/kitty/themes/noctalia.conf` into Stow dotfiles tree.

## [2.25.0] - 2026-09-14
### Added
- **Native Metadata-Driven Keybinding Architecture (`helpers.lua`)**:
  - Implemented `helpers.lua` (`~/.config/hypr/helpers.lua` in `core/.config/hypr/helpers.lua`) providing native compositor integration:
    - **Metadata-Driven `bind()` (`helpers.bind`)**: Automatically injects human-readable descriptions into Hyprland's internal C++ binding registry (`options.description`), exposing all 139 compositor bindings to live IPC queries. Bare commands are automatically wrapped in systemd cgroups via `uwsm-app --`.
    - **Native Focus-or-Launch (`helpers.launch_or_focus`)**: Programmatically queries `hl.get_windows()` across all workspaces. If the target application class or title exists, Hyprland focuses its address directly (`hl.dispatch(hl.dsp.focus({ window = "address:" .. client.address }))`). If the active window is already the application, it cycles seamlessly between open instances. Spawns cleanly via `uwsm-app` if absent. Applied across Zen Browser, Dolphin, LazyGit, LazyDocker, Neovim Notes, YouTube, and Yazi.
    - **Dynamic Context-Aware Key Routing (`helpers.is_terminal` / `helpers.route_key`)**: Inspects `hl.get_active_window().class` at trigger time to route macOS-style shortcuts:
      - Line Delete (`SUPER + BackSpace`): Dispatches `CTRL + U` in terminal emulators (`kitty`, `ghostty`, `alacritty`, `foot`), and `Shift + Home` followed by `BackSpace` in GUI applications.
      - Smart Copy (`SUPER + C`): Dispatches `CTRL + SHIFT + C` in terminals (preventing process `SIGINT` interruption), and native `CTRL + C` in GUI applications (preventing accidental browser DevTools DOM inspection).
      - Smart Paste (`SUPER + V`): Dispatches `CTRL + SHIFT + V` in terminals and `CTRL + V` in GUI applications.
  - **Live IPC Keybindings Cheatsheet (`hypr-keybinds-menu`)**:
    - Deployed `~/.local/bin/hypr-keybinds-menu` (`core/.local/bin/hypr-keybinds-menu`).
    - Queries runtime bindings directly from the compositor via `hyprctl binds -j`, decodes modifier masks (`SUPER`, `ALT`, `CTRL`, `SHIFT`), filters entries with descriptions, and presents a fast, searchable popup via `fzf`.
    - Mapped to `SUPER + K` in a floating, centered Kitty window (`class = "^(Keybindings)$"`).

## [2.24.0] - 2026-09-14
### Added
- **Multi-PC Modular 3-Tier Architecture Migration (Ported from `omarchy-dots`)**:
  - Restructured monolithic flat dotfiles into 3 decoupled tiers:
    - **Tier 1 (`core/`)**: Universal configs across all machines (`~/.config/hypr/`, `noctalia`, `kitty`, `alacritty`, `fish`, `btop`, `waypaper`, `gtk`, `swayimg`, `zigoku`, `easyeffects`, `niri`, `core/.local/bin/`, `core/.local/share/applications/`, `core/packages.txt`).
    - **Tier 2 (`profiles/`)**: Hardware-specific profiles (`macbook-t2`, `desktop`, `surface`, `laptop`). Each profile contains isolated `.config/hypr/config/profile/` modules (`monitors.lua`, `environment.lua`, `inputs.lua`), `packages.txt`, `setup.sh`, and `gotchas/`.
    - **Tier 3 (`agents/`)**: Dynamically probed AI System Personalization skill (`init-skill.sh`, `SKILL.md.template` -> `SKILL.md`, `references/hardware.md`, and dynamic gotchas symlinking).
  - **Dynamic Hyprland Lua Bootstrap**: `hyprland.lua` loads universal core modules and dynamically resolves hardware overrides via `pcall(require, "config.profile.environment")`, `pcall(require, "config.profile.monitors")`, and `pcall(require, "config.profile.inputs")`.
  - **Wallpaper Fork Integration & Sync Utility**:
    - Created `core/.local/bin/cachy-sync-wallpapers` syncing shallow clone (`--depth 1`) from `https://github.com/JValdivia23/walls.git` into `~/Pictures/Wallpapers/dharmx-walls` (1567 curated wallpapers) with fallback to `dharmx/walls.git`.
    - Automatically creates convenience symlink `~/Wallpapers -> ~/Pictures/Wallpapers`.
    - Fixed Hyprland `Alt+Space` wallpaper selector keybinding to invoke `waypaper` directly from `$PATH`.
  - **New Master Installer (`install.sh`)**: Built-in hardware detection (DMI, PCI, chassis), CLI flags (`--profile`, `--profiles`, `--dry-run`, `--only-stow`, `--only-packages`), non-destructive backup, directory symlink sanitization, automated wallpaper sync on fresh setup, and profile post-install hooks.
  - **Fresh Install Audit Remediations**: Verified zero hardcoded usernames (`$HOME` / `sh -c` portable paths), corrected script executable permissions, added Stow ignore for skill init scripts, and confirmed clean Hyprland config status (`hyprctl configerrors`).

## [2.23.0] - 2026-09-10
### Added
- **Two-Way Quick SSH Shortcuts (`jmvp` <-> `java-cu`)**:
  - **`ssh jmvp` (Laptop -> Remote `10.0.0.108`)**:
    - Configured Host entry in [`~/.ssh/config`](file:///home/java1127/.ssh/config) for `jmvp` and `10.0.0.108`.
    - Configured user `jmvp`, primary identity keys (`id_ed25519`, `id_rsa`), and 8-hour socket multiplexing (`ControlMaster auto`, `ControlPath ~/.ssh/sockets/%r@%h:%p`).
  - **`ssh java-cu` (Remote `10.0.0.108` -> Laptop `10.0.0.8`)**:
    - Generated dedicated `ed25519` key pair on `jmvp@10.0.0.108` and added public key to [`~/.ssh/authorized_keys`](file:///home/java1127/.ssh/authorized_keys).
    - Configured `~/.ssh/config` on `jmvp@10.0.0.108` mapping `Host java-cu` to `java1127@10.0.0.8` with socket multiplexing.
    - Verified instantaneous two-way passwordless connection in both directions.

## [2.22.0] - 2026-09-09
### Added
- **Installed `cliamp` Terminal Music Player (`cliamp-bin` `2.2.0-1`) & `yt-dlp` (`2026.08.19-1`)**:
  - Packaged and installed retro Winamp 2.x-inspired terminal music player `cliamp` v2.2.0 from AUR via `cliamp-bin`.
  - Installed `yt-dlp` from official repos as an audio extraction and online streaming provider dependency.
  - Deployed system executable `/usr/bin/cliamp`, desktop application entry `/usr/share/applications/cliamp.desktop`, and hicolor application icons.
  - Native MPRIS D-Bus integration connects directly to Noctalia's media widgets and Hyprland media shortcuts (`XF86AudioPlay`, `Next`, `Prev`).

## [2.21.0] - 2026-09-07
### Changed
- **Full System Upgrade & Linux 7.2.3 Kernel (`7.2.3-1-cachyos`)**:
  - Upgraded kernel from `7.2.2-1-cachyos` to **`7.2.3-1-cachyos`** alongside `linux-cachyos-headers`, `cpupower`, and `bpf`.
  - Upgraded **Noctalia** Wayland shell from `5.0.0_beta.10-1.1` to **`5.0.1-1.1`** (official point release out of beta).
  - Updated Hyprland compositor stack: `hyprland` `0.56.2-2.1`, `aquamarine` `0.15.0-2.1`, `hypridle` `0.1.8-2.1`, `hyprlock` `0.9.6-3.1`, `hyprutils` `0.14.2-1.1`, and `xdg-desktop-portal-hyprland` `1.4.1-2.1`. Zero Hyprland config errors reported (`hyprctl configerrors`).
  - Updated **LuaJIT** to `2.1.1788460057+24c20c9-1.1` (underlying Hyprland Lua modular config engine).
  - Upgraded **Fish Shell** to **`4.9.2-1`** (from `4.8.1`).
  - Updated web browser suite: **Zen Browser `1.22b-1`**, **Firefox `155.0.1-1`**, and **Brave Origin `1:1.94.121-1`**.
  - Updated user & CLI utilities: **Swayimg `5.6-1.1`**, **Lazygit `0.65.0-1.1`**, **Yazi `26.9.1-2.1`**, and **scx-scheds `1.1.3-2`**.
  - Verified post-reboot hardware health: Apple T2 Bridge Controller, OLED Touch Bar (`tiny-dfr.service` active), fan daemon (`t2fanrd.service` active), and PipeWire direct ALSA routing for `Apple Audio Device Speakers`.

## [2.20.0] - 2026-09-03
### Changed
- **rEFInd Boot Theme Modernization (`rEFInd-minimal-black`)**:
  - Replaced the bright, high-glare `rEFInd-minimal` theme (light silver background `#eceee3`) with **`rEFInd-minimal-black`** in `/boot/EFI/refind/themes/rEFInd-minimal-black/`.
  - Configured a true solid black canvas (`#000000`) with subtle monochrome gray icons (~`RGB: 225, 225, 225`) and minimalist selection indicator.
  - Linked monochrome gray Arch Linux logo (`os_arch.png`) for CachyOS and Limine (`os_cachyos.png`, `os_limine.png`, `limine_x64.png`), paired with the gray Apple logo (`os_mac.png`) for macOS dual-boot.
  - Updated `/boot/EFI/refind/refind.conf` to include `themes/rEFInd-minimal-black/theme.conf` while retaining the 3-second auto-boot countdown and default CachyOS target.
  - Documented update in [`references/gotchas/apple-t2.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L104-L114).

## [2.19.0] - 2026-09-03
### Fixed
- **Laptop Lid Suspend & Clamshell Thermal Overheating Prevention**:
  - Diagnosed battery exhaustion and extreme chassis heat when closed: [`/etc/systemd/logind.conf.d/omarchy-lid.conf`](file:///etc/systemd/logind.conf.d/omarchy-lid.conf) had `HandleLidSwitch=ignore` and `HandleLidSwitchExternalPower=ignore` enabled, preventing systemd-logind from suspending the laptop when the lid closed.
  - Reconfigured `omarchy-lid.conf` to `HandleLidSwitch=suspend` and `HandleLidSwitchExternalPower=suspend`, while retaining `HandleLidSwitchDocked=ignore` for external display clamshell workstations.
  - Reloaded `systemd-logind` configuration via `SIGHUP` (`systemctl kill -s HUP systemd-logind`).
  - Enhanced [`~/.local/bin/hypr-lid-handler`](file:///home/java1127/.local/bin/hypr-lid-handler) in dotfiles (`~/dotfiles/bin/.local/bin/hypr-lid-handler`):
    - Added Touch Bar OLED backlight (`appletb_backlight`) preservation: saves active level to `/tmp/hypr_tb_backlight_saved_${UID}` and shuts off OLED display on lid close, restoring brightness on lid open.
    - Integrated with `power-profiles-daemon`: saves current profile and enforces `powerprofilesctl set power-saver` on lid close, restoring previous profile on open.
  - Documented updated architecture in [`references/gotchas/hyprland.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/hyprland.md) and [`references/config-paths.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/config-paths.md).

## [2.18.0] - 2026-09-01
### Changed
- **Full System Upgrade & Linux 7.2 Kernel (`7.2.2-1-cachyos`)**:
  - Upgraded kernel from `7.1.8-1-cachyos` to **`7.2.2-1-cachyos`** alongside `linux-cachyos-lts` `6.18.48-1`.
  - Updated **Noctalia** shell to `5.0.0_beta.10-1.1`.
  - Updated web browser suite: **Firefox 154.0.1**, **Zen Browser 1.21.16b**, and **Brave Origin 1.94.117**.
  - Updated KDE Frameworks & Dolphin to **`26.08.0-5.1`** / Qt 6.11.2.
- **Apple T2 BCE Driver Transition & mkinitcpio Multi-Kernel Compatibility**:
  - Diagnosed `mkinitcpio` build failure on Linux 7.2 due to legacy hardcoded `MODULES+=(apple-bce)` in [`/etc/mkinitcpio.conf.d/11-chwd.conf`](file:///etc/mkinitcpio.conf.d/11-chwd.conf).
  - Modernized `11-chwd.conf` with optional `?` tags: `MODULES+=(apple-bce? t2bce_core? t2bce_vhci? t2bce_dma? applesmc-t2?)` to support both Linux 7.2+ modular `t2bce` drivers and LTS `apple-bce`.
  - Rebuilt all Limine UKI and initramfs boot images cleanly.
- **Keyboard Backlight Clamshell / Lid Preservation & Idle Dimming**:
  - Diagnosed keyboard backlight starting at 0% (off) after opening laptop lid: [`~/.local/bin/hypr-lid-handler`](file:///home/java1127/.local/bin/hypr-lid-handler) turned off `apple::kbd_backlight` on lid close without saving previous level.
  - Updated `hypr-lid-handler` to save active brightness level to `/tmp/hypr_kbd_backlight_saved_${UID}` on `close` and restore the saved level automatically on `open`.
  - Added 150s (2.5 min) idle listener to [`~/.config/hypr/hypridle.conf`](file:///home/java1127/.config/hypr/hypridle.conf) (`brightnessctl -s -d "apple::kbd_backlight" set 0%` and `brightnessctl -r`), turning off keyboard backlighting alongside screen and Touch Bar dimming.
- **Unified Noctalia On-Screen Display (OSD) for Screen & Keyboard Brightness**:
  - Deployed [`~/.local/bin/hypr-screen-brightness`](file:///home/java1127/.local/bin/hypr-screen-brightness) to route display brightness adjustments on `gmux_backlight` to `noctalia msg brightness-osd <percent>`, showing Noctalia's native progress bar on keypress.
  - Replaced `notify-send` in [`~/.local/bin/hypr-kbd-brightness`](file:///home/java1127/.local/bin/hypr-kbd-brightness) with `noctalia msg keyboard-backlight-osd <percent>`, replacing stacked notification cards with a single unified keyboard brightness OSD bar.
  - Updated [`~/.config/hypr/config/binds.lua`](file:///home/java1127/.config/hypr/config/binds.lua) hardware brightness bindings with `repeating = true`.
- **Skill Self-Improvement & Wayland IPC Dispatch**:
  - Updated [`SKILL.md`](file:///home/java1127/.agents/skills/system-personalization/SKILL.md) Rule 8, [`terminal-ssh.md`](file:///home/java1127/.agents/skills/system-personalization/references/gotchas/terminal-ssh.md), and [`hyprland.md`](file:///home/java1127/.agents/skills/system-personalization/references/gotchas/hyprland.md) to properly export `HYPRLAND_INSTANCE_SIGNATURE` and invoke Hyprland's native `hl.exec_cmd` for elevated background terminal prompts.

## [2.17.0] - 2026-08-20
### Changed
- **Graphics & Vulkan Driver Stack Update (Mesa 26.2.1)**:
  - Synchronized repository databases and updated graphics stack to **Mesa 26.2.1** (`mesa`, `lib32-mesa`, `vulkan-radeon`, `lib32-vulkan-radeon`, `vulkan-intel`, `lib32-vulkan-intel`, `opencl-mesa`, `lib32-opencl-mesa`, `vulkan-mesa-implicit-layers`, `lib32-vulkan-mesa-implicit-layers` `3:26.1.6-1` -> `3:26.2.1-1`).
  - Verified Vulkan 1.4 driver instance (`Mesa 26.2.1-arch3.1`, RADV POLARIS11) and VA-API hardware acceleration (`radeonsi`) on discrete AMD Radeon Pro 560X.

## [2.16.0] - 2026-08-17
### Added
- **Clamshell & Ultra-Low Idle Power Architecture (Lid-Closed Mode)**:
  - Configured system to allow background tasks (downloads, music, servers, SSH) to run with the laptop lid closed without forcing immediate sleep.
  - Set `HandleLidSwitch=ignore` and `HandleLidSwitchExternalPower=ignore` in [`/etc/systemd/logind.conf.d/omarchy-lid.conf`](file:///etc/systemd/logind.conf.d/omarchy-lid.conf).
  - Deployed [`~/.local/bin/hypr-lid-handler`](file:///home/java1127/.local/bin/hypr-lid-handler) in dotfiles (`~/dotfiles/bin/.local/bin/hypr-lid-handler`):
    - **Lid Close (`switch:on:Lid Switch`)**: Locks session via Noctalia/loginctl, powers off primary Retina display (`eDP-1`) via Wayland DPMS, powers down keyboard backlighting (`apple::kbd_backlight`), and sets power saving on GPU and CPU.
    - **Lid Open (`switch:off:Lid Switch`)**: Powers display (`eDP-1`) back on via Wayland DPMS and restores active power profiles.
  - Bound Hyprland switch directives in [`~/.config/hypr/config/binds.lua`](file:///home/java1127/.config/hypr/config/binds.lua) with `{ locked = true }`.
  - Enhanced [`/usr/local/bin/amdgpu-power-switch.sh`](file:///usr/local/bin/amdgpu-power-switch.sh) to toggle Intel Turbo Boost (`/sys/devices/system/cpu/intel_pstate/no_turbo`) on battery/clamshell, locking idle CPU draw to $\approx 1.0\text{W} - 1.8\text{W}$ and eliminating thermal spikes inside the closed chassis.

## [2.15.0] - 2026-08-17
### Fixed
- **Touch Bar Sleep/Resume Controller Recovery & Driver Blacklist**:
  - Diagnosed Touch Bar unresponsiveness: on wakeup or boot, setting USB device `05ac:8302` directly to Configuration 2 caused BridgeOS probe timeout (`-110` / `ETIMEDOUT: Failed to send message`). In addition, the in-tree `hid_appletb_kbd` driver auto-claimed the interface and dropped VHCI endpoints (`bce_vhci_drop_endpoint 6:11`).
  - Blacklisted `hid_appletb_kbd` in [`/etc/modprobe.d/blacklist-touchbar.conf`](file:///etc/modprobe.d/blacklist-touchbar.conf) and staged in `~/dotfiles/scripts/blacklist-touchbar.conf`.
  - Deployed [`/etc/udev/rules.d/99-touchbar-tiny-dfr.rules`](file:///etc/udev/rules.d/99-touchbar-tiny-dfr.rules) to manage Touch Bar input, display, and backlight aliases cleanly without change loops.
  - Updated [`/usr/local/bin/t2-sleep-helper`](file:///usr/local/bin/t2-sleep-helper) to cycle `bConfigurationValue` `0 -> 2`, allowing BridgeOS to open its readiness window before loading `appletbdrm`.
  - Created and enabled [`/etc/systemd/system/t2-touchbar-setup.service`](file:///etc/systemd/system/t2-touchbar-setup.service) to automatically run `t2-sleep-helper post` upon boot.
  - Hardened [`/etc/systemd/system/tiny-dfr.service`](file:///etc/systemd/system/tiny-dfr.service) with `BindsTo=dev-tiny_dfr_display.device` so `tiny-dfr` never mistakenly opens primary GPU cards.
  - Documented complete architecture and recovery cycle in [`references/gotchas/apple-t2.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L7-L28).

## [2.14.0] - 2026-08-15
### Fixed
- **Apple Touch Bar Sleep & Resume Recovery (`tiny-dfr` & `appletbdrm`)**:
  - Diagnosed Touch Bar failure on MacBookPro15,1 (Apple T2 + discrete AMD Radeon Pro 560X): forcing experimental hardware mode (`hid-appletb-kbd`) caused BridgeOS transfer queue failures (`URB failed: 3`) and VHCI endpoint drops (`bce_vhci_drop_endpoint 6:11`).
  - Restored canonical T2 Userspace DRM architecture using native **`tiny-dfr`** and **`appletbdrm`** (Configuration 2 with `hid-multitouch`).
  - Updated [`/usr/local/bin/t2-sleep-helper`](file:///usr/local/bin/t2-sleep-helper):
    - **Pre-suspend**: Gracefully stops `tiny-dfr.service`, unloads `appletbdrm` and `hid_appletb_bl`, and saves backlight brightness to `/run/tb_brightness`.
    - **Post-resume**: Reloads `hid_appletb_bl` and `appletbdrm`, restores backlight brightness, and automatically restarts `tiny-dfr.service` upon DRM device appearance.
  - Documented root cause and architecture in [`references/gotchas/apple-t2.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L9-L26).

## [2.13.0] - 2026-08-14
### Fixed
- **Web App High-Resolution Icons & XDG Multi-Resolution Hierarchy**:
  - Replaced corrupted/disguised JPEG web app icon files (`AllAnime.png`, `Hanime.png`) with clean, pixel-perfect 512x512 RGBA PNGs and vector SVGs.
  - Deployed official YouTube play button logo (SVG + 512x512 RGBA PNG on transparent background) as preferred by user.
  - Generated and installed multi-resolution icon assets across `~/.local/share/icons/hicolor/{16x16,24x24,32x32,48x48,64x64,128x128,256x256,512x512}/apps/` and `~/.local/share/pixmaps/`.
  - Updated [`scripts/02-stow.sh`](file:///home/java1127/dotfiles/scripts/02-stow.sh) and [`bin/.local/bin/cachy-webapp-install`](file:///home/java1127/dotfiles/bin/.local/bin/cachy-webapp-install) to automatically link web app icons to `hicolor` and `pixmaps` and rebuild GTK/XDG icon caches.
  - Documented troubleshooting in [`references/gotchas/wayland-noctalia.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/wayland-noctalia.md#L86-L98).

## [2.12.0] - 2026-08-14
### Added
- **Dual-Boot OS Picker & macOS APFS Auto-Discovery (`rEFInd` + `rEFInd-minimal`)**:
  - Installed `refind` boot manager to `/boot/EFI/refind/` and configured it as the primary UEFI boot priority (`Boot0001`, `BootOrder: 0001,0000,0080`).
  - Deployed the **`rEFInd-minimal`** theme with dark canvas, monochrome icons, and custom `os_cachyos.png` branding in `/boot/EFI/refind/themes/rEFInd-minimal/`.
  - Configured `/boot/EFI/refind/refind.conf` with `timeout 3` and `default_selection "limine,vmlinuz,cachyos"`, providing an automatic 3-second countdown to boot CachyOS while giving direct 1-click access to macOS APFS without requiring the hardware `Option` key.
  - Generated `/boot/refind_linux.conf` with optimized kernel parameters and installed `btrfs_x64.efi` driver.
  - Documented dual-boot architecture and fallback procedures in [`references/gotchas/apple-t2.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L99-L111).

## [2.11.0] - 2026-08-14
### Fixed
- **Workspace Window Move Keybinding Error (`SUPER + SHIFT + 1..3`)**:
  - Diagnosed `[ERR] Monitor not found` runtime error when moving windows across workspaces: [`~/.config/hypr/config/binds.lua`](file:///home/java1127/.config/hypr/config/binds.lua) contained conflicting duplicate bindings targeting `MONITOR1`, `MONITOR2`, and `MONITOR3` which were initialized to empty strings `""` in [`variables.lua`](file:///home/java1127/.config/hypr/config/variables.lua).
  - Removed duplicate monitor bindings from `binds.lua`, enabling the full workspace movement loop (`SUPER + SHIFT + [1-9, 0]`) to operate cleanly for all 10 workspaces.
  - Documented root cause and solution in [`references/gotchas/hyprland.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/hyprland.md#L97-L104).

## [2.10.0] - 2026-08-14
### Fixed
- **Waypaper GUI Progressive Rendering & Instant Launch (`ALT + Space`)**:
  - Diagnosed slow startup delay (7+ seconds) and apparent missing cache: stock `/usr/bin/waypaper` unconditionally displayed a `"Caching wallpapers..."` banner on every launch and blocked until 1,700+ GTK buttons were created.
  - Executed a multi-threaded Python pre-cacher script (`ThreadPoolExecutor` + PIL) generating all 1,644 PNG thumbnails into `~/.cache/waypaper/` in parallel.
  - Deployed optimized Waypaper build in `~/.local/share/waypaper` with dedicated virtualenv (`~/.local/share/waypaper/venv`):
    - **Two-Stage Progressive Rendering**: Renders first 20 wallpapers in `< 0.05s` and caps processing batches to 160 items for fast launch and smooth scrolling.
    - **Smart Caching Label**: Only displays `"Caching new wallpapers..."` if an image is actually missing from disk.
    - **Live Daemon Status Badge**: Displays `🟢 Active` / `🔴 Inactive` rotation status next to interval timer.
  - Updated `ALT + Space` in [`~/.config/hypr/config/binds.lua`](file:///home/java1127/.config/hypr/config/binds.lua#L121) to execute `~/.local/share/waypaper/venv/bin/waypaper` and created `~/.local/bin/waypaper` symlinks.

## [2.9.0] - 2026-08-14
### Fixed
- **Apple Touch Bar Full Hardware Mode & Function Keys Configuration**:
  - Configured [`/etc/modprobe.d/touchbar.conf`](file:///etc/modprobe.d/touchbar.conf) with `options hid_appletb_kbd mode=1 fntoggle=1 double_press_switch_time=500` to set `F1`–`F12` Function Keys as the active default row, with dynamic switching to Media controls on `Fn` hold or double-tap toggle.
  - Disabled and stopped obsolete `supergfxd.service` (ASUS ROG GPU daemon) to prevent spurious PCIe bus rescans and T2 VHCI endpoint resets.
  - Documented Touch Bar architecture and modes in [`references/gotchas/apple-t2.md`](file:///home/java1127/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L7-L23).

## [2.8.0] - 2026-08-14
### Added
- **Automatic Screen Dimming & Sleep Daemon (`hypridle`)**: Installed `hypridle` and `hyprlock`, configured [`~/.config/hypr/hypridle.conf`](file:///home/java1127/.config/hypr/hypridle.conf), and added autostart into [`~/.config/hypr/config/autostart.lua`](file:///home/java1127/.config/hypr/config/autostart.lua).
  - 2.5 min inactivity: Dims display brightness to 10% (`brightnessctl -s set 10%`).
  - 5.0 min inactivity: Cuts display backlight signal (`hyprctl dispatch dpms off`, 0W backlight).
  - 15 min inactivity: Automatically suspends machine to S3 deep sleep.
  - Fully integrated with Noctalia's Caffeine toggle (`SUPER + CTRL + I`) via Wayland `ext_idle_notifier_v1` and DBus idle inhibitors.
- **PCIe ASPM Low-Power Switching**: Enhanced [`/usr/local/bin/amdgpu-power-switch.sh`](file:///usr/local/bin/amdgpu-power-switch.sh) to automatically set PCIe Active State Power Management to `powersupersave` on battery and restore `default` on AC.

## [2.7.0] - 2026-08-14
### Fixed
- **Apple T2 Audio Subsystem Recovery & Sleep Queue Integrity**:
  - Diagnosed missing YouTube audio caused by Apple T2 BridgeOS queue corruption (`apple-bce: SQ registration failed (34/74)`) after waking from suspend, which caused PipeWire to fall back to `Dummy Output`.
  - Reloaded the `apple_bce` kernel module to reset the BridgeOS communication channels, immediately restoring the ALSA `Apple Audio Device Speakers` sink (`alsa_output.pci-0000_02_00.3.Speakers`) and `BuiltinMic` source in PipeWire.
  - Updated [`/usr/local/bin/t2-sleep-helper`](file:///usr/local/bin/t2-sleep-helper) to preserve `apple_bce` and `aaudio` attachments across suspend/resume instead of unbinding them, maintaining BridgeOS Submission Queue integrity.
  - Documented the root cause and module reload recovery procedures in [`references/gotchas/apple-t2.md`](file:///home/java1127/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L30-L42).

## [2.6.0] - 2026-08-14
### Added
- **Brave Browser GPU & Wayland Flags**: Created [`~/.config/brave-origin-flags.conf`](file:///home/java1127/.config/brave-origin-flags.conf) and [`~/.config/brave-flags.conf`](file:///home/java1127/.config/brave-flags.conf) enabling native Wayland surfaces (`--ozone-platform-hint=auto`), VA-API video decode & encode (`VaapiVideoDecodeLinuxGL`), zero-copy rasterization, and GPU acceleration for both the browser and all installed WebApps.
- **Zen Browser WebRender & VA-API Configuration**: Created [`user.js`](file:///home/java1127/.zen/Profiles/80a9d579.Default%20%28release%29/user.js) in the active profile enabling WebRender GPU compositing (`gfx.webrender.all = true`), direct VA-API hardware video decode (`media.ffmpeg.vaapi.enabled = true`), XDG Desktop Portal file picker, calibrated smooth scrolling, and 512 MB memory caching.

## [2.5.0] - 2026-08-14
### Added
- **Dynamic AMD GPU Power Management (`udev`)**: Created `/usr/local/bin/amdgpu-power-switch.sh` and `/etc/udev/rules.d/99-amdgpu-power.rules` to automatically switch AMD Radeon Pro 560X PowerPlay profile modes based on AC adapter state:
  - **On Battery (`online == 0`)**: Automatically engages `POWER_SAVING` (`pp_power_profile_mode = 2` / `power_dpm_force_performance_level = manual`), allowing core clocks to idle at 214 MHz (saving ~10–12 W continuous).
  - **On AC (`online == 1`)**: Restores `BOOTUP_DEFAULT` (`pp_power_profile_mode = 0` / `power_dpm_force_performance_level = auto`) for peak graphics throughput.

## [2.4.0] - 2026-08-14
### Changed
- **Disabled Hyprland Window Swallowing**: Set `enable_swallow = false` in [`~/.config/hypr/config/misc.lua`](file:///home/java1127/.config/hypr/config/misc.lua). Prevents child processes (such as elevated sudo/password prompts and agent subshells) from swallowing the parent Kitty terminal, ensuring all newly opened windows tile side-by-side cleanly in the dwindle layout.
- **Hyprland Troubleshooting Documentation**: Documented window swallowing gotcha and fix in [`references/gotchas/hyprland.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/hyprland.md#L75-L84).

## [2.3.0] - 2026-08-14
### Added
- **AMD GPU Video Acceleration & Compute**: Configured explicit `LIBVA_DRIVER_NAME=radeonsi`, `VDPAU_DRIVER=radeonsi`, and `RUSTICL_ENABLE=radeonsi` in [`~/.config/uwsm/env`](file:///home/java1127/.config/uwsm/env) and [`~/.config/hypr/config/environment.lua`](file:///home/java1127/.config/hypr/config/environment.lua) to route hardware video decoding and OpenCL directly to the AMD Radeon Pro 560X (`amdgpu`).
- **Diagnostics Tools**: Installed `libva-utils` (`vainfo`) and `vulkan-tools` (`vulkaninfo`) for GPU capability auditing.
- **Terminal Greeting Banner**: Fixed `fastfetch-custom` key parsing to dynamically discover single-GPU setups (`GPU: AMD Radeon Pro 560X (dGPU)`), Apple Retina display, battery status, and audio devices without hardcoded dual-GPU ASUS keys.

## [2.2.0] - 2026-08-14
### Added
- **Thermals & Fan Management**: Configured `/etc/t2fand.conf` with exponential fan curves (`low_temp=50`, `high_temp=78`) and enabled `t2fanrd.service` to prevent thermal throttling on the 8-core Intel Core i9-9880H.
- **Touch Bar OLED Protection**: Enabled `EnablePixelShift = true` in `/etc/tiny-dfr/config.toml` and restarted `tiny-dfr.service` to prevent burn-in on the OLED Touch Bar.
- **Audio Diagnostics & Clean Baseline**: Diagnosed EasyEffects 8.2 plugin range validation conflicts on `mbp.json` and reverted to a clean, direct PipeWire + WirePlumber routing for `Apple Audio Device Speakers` (`alsa_output.pci-0000_02_00.3.Speakers`) with verified playback.


## [2.1.0] - 2026-08-14

### Changed
- Audited and updated the `system-personalization` skill for **`cachyos-cu`** (**Apple MacBook Pro 15,1**):
  - Updated hardware reference with Intel Core i9-9880H CPU, AMD Radeon Pro 560X discrete GPU, 16 GiB RAM, and Apple Retina 2880x1800 display.
  - Documented Apple T2 chip subsystems (`apple-bce`, Touch Bar via `tiny-dfr`, Apple Audio via `aaudio`, Broadcom BCM4364 Wi-Fi, and `suspend-fix-t2.service`).
  - Removed obsolete ASUS ROG / NVIDIA PRIME / AniMe Matrix documentation and gotchas.
  - Removed nonexistent offline docs references from `SKILL.md`.
  - Updated `scripts/snapshot.sh` with automatic `HYPRLAND_INSTANCE_SIGNATURE` socket discovery and full package auditing.

## [2.0.0] - 2026-08-13
### Added
- Multi-compositor support for **Niri** in `hyprland-dots` dotfiles repository:
  - Created `niri/.config/niri/cfg/keybinds.kdl` linking **`Alt + Space`** to toggle Noctalia wallpaper selector (`qs -c noctalia-shell ipc call wallpaper toggle || waypaper`).
  - Added `niri` to `STOW_PKGS` in `scripts/02-stow.sh` for automatic deployment and conflict backups.
- Successfully deployed and validated `hyprland-dots` on remote MacBook Pro running CachyOS Niri (`10.0.0.2`).

## [1.15.0] - 2026-08-10
### Added
- Configured Hyprland `cursor` settings in [`~/.config/hypr/config/inputs.lua`](file:///home/java1127/.config/hypr/config/inputs.lua):
  - Enabled `inactive_timeout = 3` to automatically hide the mouse cursor after 3 seconds of inactivity.
  - Enabled `hide_on_key_press = true` to automatically hide the cursor when typing.

## [1.14.0] - 2026-07-30
### Changed
- Created dedicated diagnostics profile container directory (`~/.config/brave-webapps/containers/diagnostics`) allowing persistent history, cookies, and local session data across launches while remaining isolated from the primary Brave profile.

## [1.13.0] - 2026-07-28
### Added
- Installed **`swayimg`** for instant Wayland image and vector previews.
- Created `~/.local/bin/hypr-quicklook` script to trigger floating Quick Look previews over Dolphin.
- Set **Satty** (`satty.desktop`) as default image viewer across standard MIME types.
- Configured floating window rules for `swayimg` in [`~/.config/hypr/config/windowrules.lua`](file:///home/java1127/.config/hypr/config/windowrules.lua).
- Mapped **`ALT` + `Return`** (`Alt+Enter`) in [`~/.config/hypr/config/binds.lua`](file:///home/java1127/.config/hypr/config/binds.lua) to trigger Quick Look preview overlay.
- Configured **Kitty** as default terminal in `~/.config/kdeglobals` and mapped **`F4`** in Dolphin to launch Kitty in the active folder.

## [1.12.0] - 2026-07-28
### Added
- Installed **LocalSend** (`localsend` v1.17.0-4) via `pacman` for cross-platform local network file sharing.
- Configured **UFW Firewall** rules (`53317/tcp` and `53317/udp`) to allow LocalSend discovery and transfer across the local network.

## [1.10.0] - 2026-07-25
### Changed
- Mapped `SUPER + C` (`CTRL, SHIFT, C`), `SUPER + V` (`CTRL, V`), `SUPER + X` (`CTRL, X`), `SUPER + Z` (`CTRL, Z`), and `SUPER + SHIFT + Z` (`CTRL, SHIFT, Z`) directly in `binds.lua` using native `hl.dsp.send_shortcut`.
- Remapped Noctalia Control Center toggle to `SUPER + E` (`noctalia msg panel-toggle control-center`).
- Remapped Noctalia Settings toggle to `SUPER + ,` (`noctalia msg settings-toggle`).

## [1.2.0] - 2026-07-21
### Added
- Added `SUPER` + `CONTROL` + `I` keybinding to `~/.config/hypr/config/binds.lua` to toggle Noctalia Caffeine (`noctalia msg caffeine-toggle`), preventing automatic screen lock and system sleep during inactivity.

## [1.1.0] - 2026-07-20
### Added
- Created native macOS text navigation bindings in `binds.lua` (`SUPER+Left/Right` for Home/End, `SUPER+Up/Down` for Doc Top/Bottom, `ALT+Left/Right` for word jump, `SUPER+Backspace` / `ALT+Backspace` for line/word deletion).
- Created `~/.local/bin/hypr-window-pop` for window pop-out and pin (`SUPER+O`).
- Created `~/.local/bin/hypr-toggle-altwin` and mapped `SUPER+ALT+K` to toggle Mac vs PC layout.
- Installed Waypaper and bound `ALT+Space` to launch wallpaper selector GUI.

## [1.0.0] - 2026-08-10 — Automated Dotfiles Repository & GNU Stow Setup
### Added
- Installed `stow` and created the `~/dotfiles` Git repository for automated machine provisioning.
- Modularized configurations into Stow package groups (`hypr`, `noctalia`, `kitty`, `alacritty`, `fish`, `btop`, `waypaper`, `gtk`, `swayimg`, `bin`, `agents`, `webapps`, `zigoku`).
- Built automated 1-command installer `install.sh` and modular provisioning scripts.
- Published repository to GitHub as [`JValdivia23/hyprland-dots`](https://github.com/JValdivia23/hyprland-dots).
