# Juxtopposed VLC Universal Dev Gotchas

Universal development-setup notes for the Juxtopposed VLC4 fork on CachyOS.
Scope: universal dev setup — NOT a hardware profile, no core package
integration or deployment hook yet.

---

## 1. Native Qt/QML VLC4-Dev Fork, Not a VLC3 Skin

- **Fact**: The Juxtopposed fork (`https://github.com/JValdivia23/juxtopposed-vlc`,
  upstream `dsojevic/juxtopposed-vlc`, branch `linux-installation` from
  `097cbdb516452914faffcce719291cf14e2f3760` at
  `/home/jmvp/work/juxtopposed-vlc`) is a native Qt/QML VLC4-dev codebase,
  not a skin or config overlay for VLC3.
- **Implication**: It cannot reuse the system `libvlc 3.0.24` install
  (untouched) or current release assets (Windows beta only). It needs its
  own isolated binary, plugin tree, and XDG config+data+cache.
- **Related**: Private repo `/home/jmvp/work/vlcdots`
  (`https://github.com/JValdivia23/vlcdots`) now has initial ani-cli history
  and resolver development on `feature/ani-cli-integration`. Native changes
  use detached `/home/jmvp/work/vlcdots-player` and separate
  `/home/jmvp/work/vlcdots-build`; validation is in progress, not deployed.
  The dotfiles consumer is NOT yet wired.
- **Branch/PR status**: Public fork `linux-installation` changes are Linux
  guide + Meson test-setup fixes, no production UI changes. Upstream DRAFT PR
  is OPEN: `https://github.com/dsojevic/juxtopposed-vlc/pull/14`
  ('Document Linux builds and fix optional-dependency test setup'); public
  `linux-installation` HEAD `cebf0a2`.

---

## 2. Approved Dev Deps Installed; Nothing Deployed

- **Fact**: User-approved installations via interactive terminal completed
  exit 0: `nasm 3.02-1.1` + `qt6-wayland 6.12.0-1.1` (universal dev/runtime
  deps), plus followup `extra/vulkan-headers 1:1.4.363.0-1` (confirmed via
  `pacman -Q`; universal dev dependency, no GPU driver changes). No VLC
  binary installed, no live VLC config changed.
- **Fact**: Deps are intentionally NOT in `core/packages.txt` — they are
  declared in the external project for eventual integration; there is no
  deployment hook yet. Do not add them to dotfiles packages until the
  integration/deployment step is explicitly approved.

---

## 3. Isolated Prefix + Build-Tree Launcher

- **Configure**: Out-of-tree `/home/jmvp/work/juxtopposed-vlc-build` with
  Meson>=1.10, `--prefix=/home/jmvp/.local/opt/juxtopposed-vlc`,
  `debugoptimized`, `wrap-mode=nofallback`, Qt enabled, medialibrary
  disabled, tests auto. Prefix is planned only (NOT installed).
- **Launchers**: In `TOP_BUILDDIR`, the dev launcher is
  `build/bin/vlc-static`; plain `bin/vlc` targets the installed prefix, so
  do not expect it to work pre-install.
- **Rule**: Never set a global plugin path or `LD_LIBRARY_PATH` to point at
  the dev tree — keep binary/plugins/XDG state isolated per run.
- **Build status (2026-10-16)**: Full `nice 10` ninja `-j2` build SUCCEEDED
  after the `vulkan-headers` install. `build/bin/vlc-static --version`
  exit 0 (VLC4-dev `1f3b575`, GCC 16.2.1). Prefix still NOT deployed —
  live `/home/jmvp/.local/opt/juxtopposed-vlc` remains absent; see §7.

---

## 4. Meson: Disabled MediaLibrary vs Hard Test Dependency

- **Symptom**: Configure fails at `test/meson.build:55` when optional
  MediaLibrary is disabled, because `test_modules_misc_media_tracks`
  hard-depends on the absent plugin.
- **Fix (source fix in dev fork, not a system patch)**: Add
  `enabled: medialibrary_dep.found()` to the `media_tracks` +
  `medialibrary` test entries in `test/modules/meson.build`. Same
  configure after the patch succeeds (800 build targets).
- **Limitation**: Missing external `medialibrary>=0.13` means the initial
  baseline has reduced library functionality, not full beta parity.

---

## 5. Anime Resume Needs Its Own State

- **Fact**: Eventual anime resume requires dedicated state: `ani-cli`
  history records only the last launched episode, and `--continue`
  advances to the next episode with no seconds-precision position.
- **Rule**: Keep watch history, tokens, and cache out of both git repos
  (`juxtopposed-vlc` fork and `vlcdots`). Runtime local state only.

---

## 6. Vulkan Loader Present ≠ Headers Present

- **Symptom**: First compile stops at step 1481/2341 in
  `modules/video_output/vulkan/platform.c` with fatal
  `vulkan/vulkan.h not found`, even though
  `vulkan-icd-loader 1.4.363.0-1.1` / `vulkan.pc` is present.
- **Root Cause**: The ICD loader package ships the runtime + pkgconfig
  file, but the C development headers live in the separate
  `extra/vulkan-headers` package, which was absent.
- **Fix**: User-approved interactive Kitty `sudo` install of
  `extra/vulkan-headers` (exit 0, `pacman -Q` confirms
  `1:1.4.363.0-1`). Universal dev dependency; no GPU driver changes.
- **Alternative**: If Vulkan output is not needed, configure with
  `-Dvulkan=disabled` instead of installing headers (not chosen; headers
  installed to keep the baseline full-featured).

---

## 7. Staged Prefix Has No RPATH — Loader Path Is Per-Process Only

- **Setup**: `meson install --no-rebuild --destdir
  /tmp/opencode/vlc-runtime-stage-78nj7tnx/stage` SUCCEEDED; live prefix
  untouched. `readelf` shows the installed `bin` needs
  `libvlc.so.12`/`libvlccore.so.9` with no RPATH.
- **Symptom**: Raw stage `--version` fails with exit 127 (loader cannot
  find the private libs).
- **Fix**: Prefix `LD_LIBRARY_PATH` per-process only:
  `LD_LIBRARY_PATH=<stage>/lib:<stage>/lib/vlc` — version + playback then
  succeed. Never export it globally; it would shadow the system install.
- **Checks**: Five Qt plugins `ldd` clean (no missing). 2s synthetic
  FFV1+PCM clip headless-decodes through EOF exit 0 in build tree and
  stage copy — decode path only, NOT real PipeWire/speaker output.
- **Native GUI proof (user-approved 8s silent test)**: Staged player with
  `QT_QPA_PLATFORM=wayland` + private XDG dirs, exit 0. Hyprland IPC shows
  its own window (class `vlc`, `xwayland:false`, `mapped:true`); logs show
  `qt_wayland`, `avcodec`, `egl_wl`, EOF. No screenshot taken (IPC/log
  evidence only); sources in `/tmp/opencode/vlc-native-wayland-e_2r2og7`.
  No hw-decode/HDR/real-audio claims.

---

## 8. Qt Tests Need Explicit Plugin Environment; Run Suites Capped

- **Symptom**: `test_qt_subtitle_timeline_scanner` fails out of the box
  because Qt tests do not inherit a plugin path or module deps.
- **Fix (by other coding agent, `modules/gui/qt/meson.build`)**: Register
  per-test `VLC_PLUGIN_PATH=build/modules` and `module_depends` on
  `filesystem` + `http` alongside the original `subtitle`/`subsdec`.
- **Results**: First full run 40/42 pass; after reconfigure, targeted
  subtitle test PASS and full suite FINAL 41 passed / 1 failed. Sole
  remaining failure is the unchanged QML
  `tst_RedesignLibrary/test_breadcrumbs` (`KeepHiddenAncestorsAvailable`,
  line 426, `opened == false`).
- **Rules**: Build Qt test prerequisites capped (`-j2`); run suites
  sequentially with fresh XDG dirs (the breadcrumb failure reproduces
  there). Cause unconfirmed — do NOT label it flaky/env-only, do NOT skip
  it, do NOT change UI to silence it (out of scope).

---

## 9. ani-cli Adapter: Terminal Detection and History Isolation

- **CLI checked**: Installed ani-cli 5.1.5 accepts a custom player/menu, but
  non-terminal stdin can replace the menu with installed rofi/dmenu. A
  headless adapter must keep stdin on a PTY, not merely set `ANI_CLI_MENU`.
- **Private adapter**: Uses fixed capture-only helper basenames on a
  child-local PATH and a temporary `ANI_CLI_HIST_DIR`; clears inherited
  `ANI_CLI_*` overrides before setting its own values. The original history
  is never passed as the writable CLI history directory.
- **Verify before playback**: Title lookup can be ambiguous. Accept a
  captured HTTP(S) stream only after the temporary history contains the
  requested provider ID and episode. Refuse mismatches rather than play a
  different series. No arbitrary VLC options come from captured JSON.
- **Fractional episode caveat**: ani-cli 5.1.5 interpolates the episode into
  regular expressions without escaping a decimal dot. A request such as
  `1.5` can match `115`, while the CLI records the requested `1.5` in its
  sandbox history. That history alone cannot prove fractional-episode
  identity. Keep fractional imports lossless, but refuse fractional playback
  until exact episode membership can be verified safely.
- **Scope**: Imported history has no timestamps, mode, quality or completion
  state. Sub/Dub and requested quality are per-request controls; ani-cli may
  fall back to its best quality. Precise resume and saved language
  preferences still need separate runtime state. Live provider availability
  is not established by fixture tests.

---

## 10. Bridge Cancellation and the Visible QML Entry Point

- **Cancellation**: Python owns a separate ani-cli process group. Send TERM
  to Python and allow its bounded group cleanup before KILL; immediately
  killing the bridge can leave provider helpers running. Bound output while
  the child runs, not only after collecting it in a temporary file.
- **Modern UI**: `NavigationModel` and `SideNavigationPane.qml` are legacy
  routes, not the default redesigned sidebar. Private Anime integration
  belongs in `RedesignLibraryNavigation.qml` and `RedesignPlayer.qml`, and
  must also work with external medialibrary disabled. Keep optional entry
  names separate from the existing Add-media `libraryCategory6`.
- **Validation separation**: The adopted source lock's smoke result does
  not validate the private Anime patch. Test the native bridge and new panel
  independently, with synthetic history and offline CLI fixtures, before
  claiming playback works.

---

## 11. Optional VLC Switches Must Be Present in the Built Binary

- **Symptom**: The private player builds successfully but startup immediately
  rejects `--no-one-instance` as an unknown option.
- **Cause**: The source guards single-instance switches with platform/DBus
  feature macros, and guards `qt-updates-notif` with `UPDATE_CHECK`. Both
  optional features are absent in this Meson build. Seeing the option in
  source does not prove that the compiled player accepts it.
- **Rule**: Probe the built binary's `--ignore-config --longhelp` under the
  same isolated XDG/plugin environment. Only pass the fixed negative safety
  switches that it actually advertises. Refuse a failed probe rather than
  guessing; do not install dependencies just to make an unnecessary flag
  exist. A compiled-out feature cannot delegate playback or check updates.
- **Offscreen smoke**: Use the dummy Qt compositor, software Qt Quick, and
  dummy video/audio outputs for invisible synthetic playback. The player
  logs `unknown Qt platform: offscreen` after successful interface creation;
  that expected platform diagnostic alone is not a QML startup failure.
  Confirm successful Qt module initialization and clean EOF/exit instead.

---

## 12. Live Wayland UI Testing: Scoped Input and Button Activation

- **Verified on the running private player**: history selection/reload,
  episode validation, Sub/Dub and requested-quality menus, library hide/show,
  Back, and Anime reopening all work with medialibrary disabled. The default
  library toggle is `Ctrl+Shift+L`. This test did not start a new stream or
  exercise cancellation; an already-loaded video's state was left unchanged.
- **Keyboard consistency**: Tab reaches the Anime controls. Space activates
  the history rows and Reload, while Enter/Return did not. Sidebar buttons
  have explicit Enter handlers and do activate with Return. Treat this as a
  recorded usability gap; no source changes were made during live testing.
- **Focus API**: use the current native dispatcher, with a verified address:
  ```lua
  hl.dispatch(hl.dsp.focus({ window = "address:" .. addr }))
  hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "Tab", window = "address:" .. addr }))
  ```
  `hl.dsp.window.focus` was absent; legacy `exec_raw("focuswindow", ...)`
  returned `ok` without focusing the target in this session. Always read
  back the active PID/address, and stop sending keys if focus changes.
- **Private captures**: the VLC client's `hyprctl -j clients` `stableId`
  worked with `grim -T`, capturing only that window rather than a monitor or
  potentially stale desktop region. Keep captures in an owned private
  `/tmp/opencode` directory and delete them after checking. Do not commit
  watch titles, screenshots, history, or stream URLs.
- **State preservation**: fingerprint history bytes and modification time
  before/after. Restore selectors and navigation state; do not restart the
  app, invoke Play, or replace the current media just to test UI controls.

---

## 13. Episode Counters Need Catalogue Metadata, Not History Inference

- ani-cli history has a last-opened episode, not a total. Count the maintained
  CLI's parsed episode-list records and verify the complete provider ID;
  never use the highest watched episode as the denominator. `Ep 3/12` means
  episode 3 was opened and 12 catalogue episodes are currently available,
  not that three episodes were completed or that the season is finished.
- ani-cli 5.1.5 has no metadata-only switch. The private totals adapter uses
  a SHA-guarded temporary script hook that exits before playback, capturing
  only the CLI's already-parsed ID and episode map. The installed script
  remains untouched; no provider scraper or full script is tracked. Keep
  unsupported versions unknown rather than running a misplaced hook.
- Show `Ep N/?` without a verified total. For gaps, episode zero, or specials,
  use `Ep N · T eps` rather than a misleading ordinal/count ratio. Fractional
  totals parsing does not remove the separate fractional-playback refusal.
- Counts belong in the app-owned persistent XDG cache, not ani-cli history
  or the temporary VLC profile. Capture the original cache base before the
  launcher overrides XDG paths. Freshness is checked on history reload;
  expired or source-mismatched entries must also leave the native in-memory
  map, otherwise its known-ID filter prevents a new lookup.
- Keep metadata separate from history-item notifications: updating totals
  must not reset the selected row, edited episode, audio, quality, or media.
  Fetch bounded visible-row batches, pause when hidden, and allow cancelled
  rows to retry when the panel reopens without turning failures into loops.
- Source-file inspection does not search `PATH` like `Popen` does. A bridge
  passing the basename `ani-cli` needs explicit executable resolution before
  reading/fingerprinting it. Test the actual bridge command with closed
  network fixtures; absolute-path unit tests alone can miss this integration
  failure.

---

## 14. Episode Transport Is Not Queue Navigation or Chapter Seeking

- VLC's redesigned Next/Previous buttons normally use
  `MainPlaylistController.next()` / `prevOrReset()`. A single resolved anime
  stream does not populate the rest of the series in that queue, so those
  actions cannot discover the adjacent episode on their own.
- ani-cli 5.1.5 has no `--next`/`--previous` command-line switches. Its
  post-play menu chooses the adjacent line in its episode list. Reuse that
  verified catalogue order, then the existing exact-episode resolver; do not
  guess with `episode + 1`, a count/max, or ani-cli's unescaped episode regex.
  Missing neighbors are boundaries, not a reason to play an unrelated queued
  file. The fractional-playback refusal remains applicable.
- **Chapters** seek inside the current media. A series **Episodes** list
  belongs beside Chapters in the play-queue panel, not inside
  `Player.chapters` or its seek API. Keep the current series list in memory;
  do not persist it as a full catalogue mirror or manufacture timestamps.
- Keep the original canonical request title, mode, and quality with the
  playback context. A resolved stream's display title can contain an episode
  suffix and is not a reliable search title. Sidebar selection and edited
  controls are also not proof of which anime is actually playing.
- Correlate playback ownership using held input-item identities, not stream
  URL equality (URLs can be duplicated, signed, or reused). A media change
  must invalidate late asynchronous requests; leaving the Anime sidebar
  should not cancel transport navigation that belongs to the player.
- Cancel requests on owned-to-owned input changes too, even within the same
  series. Matching a series key alone does not prove that a catalog reply
  belongs to the current episode or input. Preserve the resolve origin
  through final media/subtitle validation so transport failures reach the
  Episodes error channel instead of a closed Anime sidebar.
- The additive `navigation` bridge command accepts no `--cache-file` flag;
  history and totals do. Do not blindly reuse cache argv across commands:
  the production launcher always configures a cache path, so a permissive
  fake helper can hide an argparse failure. Keep strict argv coverage.

---

## 15. Native Playlist Test Fixtures Need Realistic Playback and Plugin Lifetimes

- A deliberately refused loopback stream can trigger VLC's normal error
  auto-advance when another queue item follows it. To test queued-input
  identity restoration rather than decoding, first verify the catalog is
  cached, stop the player, then select the known item without starting it.
  Do not weaken production cancellation to accommodate a failing fixture.
- A standalone Qt/libvlc test scanning build plugins can load KF6 WindowSystem,
  whose initialization parents a helper QObject to QCoreApplication. GDB
  reproduced a post-Totals `QObjectPrivate::deleteChildren` crash when
  `libvlc_release` unloaded its library before Qt destroyed that child.
  Keep the RAII libvlc owner alive until after QCoreApplication teardown;
  its temporary userdata must also survive until core release. Do not detach
  application children, leak the core, or suppress the crash. This was a test
  fixture lifetime bug, not a demonstrated crash in the normal player.

---

## 16. A User-local Alpha Needs Installed Runtime Paths, Not Build Wrappers

- Stage with `meson install --no-rebuild --strip --destdir <owned-temp>`;
  stripping changes destination copies, not mapped development modules.
  This build has no install scripts. Do not use `--tags runtime` alone:
  untagged Lua bytecode/HTTP assets would be omitted. The installed payload
  has no icon or attribution/license files by default, so bundle those
  explicitly from the pinned source.
- For resolved release prefix `R`, launch installed `R/bin/vlc` with
  per-process `LD_LIBRARY_PATH=R/lib:R/lib/vlc`, `VLC_LIB_PATH=R/lib/vlc`,
  `VLC_PLUGIN_PATH=R/lib/vlc/plugins`, `VLC_DATA_PATH=R/share/vlc`, and
  **`VLC_LIBEXEC_PATH=R/libexec/vlc`**. The latter selects the installed
  preparser/Qt-check helpers; a build-only lib path can otherwise activate
  static-helper lookup. Plugin-path overrides are additive, so the correct
  lib path matters too. Never export these paths globally.
- Actual VLC longhelp is about 379 KB here: a 256 KiB capability-probe cap
  rejects the real player despite tiny fixture tests passing. Keep bounded
  cumulative stdout/stderr capture (2 MiB in the alpha launcher), a timeout,
  and realistic large-help plus overflow regression fixtures.
- Linux can hide same-UID systemd/PAM process executables/mappings. Blindly
  refusing every unreadable same-UID process makes a normal desktop install
  unusable. A fresh install overwrites no prior payload and needs no map
  scan; updates/uninstall still check known executables and readable maps,
  and fail closed for opaque possible VLC/helpers or unknown identities.
  Do not request ptrace privileges or lower kernel security. Detection of
  opaque custom hosts with unrelated names is only best-effort.
- Qt still sets the upstream desktop identity to `vlc`; a custom menu entry
  does not guarantee separate taskbar grouping. Do not promise an unverified
  Wayland app-ID environment override or alter MIME defaults incidentally.

---

## 17. A Cold Qt-only Build Can Miss Native Runtime Plugins

- On upstream `56834cb796aa8947f499f3f965fb3df1dad4f617`, Meson setup with
  `medialibrary=disabled` fails because the new `test_src_misc_media_library_startup`
  registration unconditionally requests the absent plugin. A temporary
  `enabled: medialibrary_dep.found()` guard permits configuration without
  changing Qt tests. Keep this scratch workaround explicit in any result.
- Building only the Qt test executable/dependency targets is insufficient for
  mocked native interface startup: also build `bin/vlc-preparser-static` and
  `modules/libpreparserserializer_json_plugin.so` in that same fresh build.
  GDB showed zero `preparser msg serdes` candidates without the latter;
  preparser creation fails and interface startup returns `VLC_ENOMEM` even
  though `libvlc_new()` succeeded. Do not misreport the resulting four model
  initialization failures as product regressions. The console logger plugin
  restores diagnostics but is not the serializer fix.
- The target `modules/libhttp_plugin.so` registers as `oldhttp`. The subtitle
  scanner fixture checks modern `http`/`https` module names and skips its
  loopback cancellation test until `modules/libhttps_plugin.so` is built.
  Plain loopback HTTP does not require adding GnuTLS or keystore targets.
- Record exact revision, Qt version, platform and renderer. The QML runner
  forces offscreen internally; use the explicit `-platform minimal` argument
  for a real minimal-platform comparison. At this revision/Qt 6.12.0, the
  breadcrumb opening failure remains independently reproducible on both;
  no cause has been established. A software-renderer shader-pixel skip is
  expected and must be disclosed rather than counted as pixel coverage.
- Retest separately from installed alpha and mapped development builds.
  Share sanitized summaries, not raw Meson logs that may include inherited
  environment values. Evidence: `/tmp/opencode/vlc-master-retest-40h0oe3j/`.
