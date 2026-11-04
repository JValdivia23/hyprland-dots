# Neovim / default LazyVim and VS Code layer

## Scope and launch

Plain `nvim` now uses **LazyVim as the base editor**, with the local VS Code
plugin layered over it through `lua/plugins/vscode.lua`. This is a **universal
user configuration** from dotfiles `core/`, not a Surface-only hardware setting.
The normal executable remains `/usr/bin/nvim`; no alias or desktop shortcut was
added. `~/.config/nvim` did not exist before this default was requested.

Canonical source: `core/.config/nvim/`, exposed at `~/.config/nvim`. The existing
`core/.config/nvim-vscode/` entry point now reuses that source, but the launcher
still sets `NVIM_APPNAME=nvim-vscode` to keep its data/state/cache separate.
All three live entry points (`~/.config/nvim`, `~/.config/nvim-vscode`, and
`~/.local/bin/nvim-vscode`) are dedicated symlinks into dotfiles `core/`.

- `nvim`: ordinary LazyVim startup plus the layer, initially using Ctrl.
- `nvim-vscode --ctrl`: recommended initial scratch evaluation on Surface.
- `nvim-vscode --super`: target Super preset, **only after** host input conflicts are understood.
- `:VscodePlayground`: fresh nofile buffer. `:VscodeGuide`: test checklist.
- `nvim --clean`: stock Neovim without LazyVim or the layer, deleting nothing.
- For Fish, `env LAZYVIM_VSCODE_DIR=/path/to/checkout nvim` overrides the default
  plugin directory `~/work/lazyvim-vscode` in either entry point.

Wrapper configuration is `~/.config/nvim/lua/plugins/vscode.lua`. Restart after
changes; do not reload the engine input manager by calling its setup twice.
Generated lockfiles are `~/.local/state/nvim/lazy-lock.json` and
`~/.local/state/nvim-vscode/lazy-lock.json`; use equivalent XDG paths if customized.
Restore with `:Lazy restore`. Language tools/parser auto-install remain opt-in in
`~/.config/nvim/lua/plugins/baseline.lua` during the experimental editing milestone.

The shared configuration explicitly retains its root in lazy.nvim's
`performance.rtp.paths`: lazy.nvim resets runtimepath during setup. Do not leave
an empty `nvim-vscode/lua/plugins/` directory shadowing the shared `plugins`
import; the migration removed only these emptied directories after moving files.

## Current Surface shortcut conflicts (read-only audit, 2026-10-20)

The live compositor, not Neovim, currently owns Super+D (fullscreen), Super+K
(keybindings menu), Super+Z/Shift+Z (history), and **Super+Shift+L (lock/suspend)**.
Do not use Super+Shift+L as an editor test before separately releasing that
binding. Kitty's current Super copy/paste maps are also terminal actions, not
proof of Neovim modifier forwarding. The installation did not change any of
these bindings. Ctrl-preset success is not a Super-forwarding pass.

`herdr` was not present on PATH at installation. If a multiplexer is later used,
compare a direct Kitty session with `herdr`; do not infer mouse or keyboard
protocol delivery from headless tests.

## Evidence and limitations

LazyVim v16.0.1, Neovim 0.12.6, Blink v1.10.2 (Lua fuzzy matcher), and the pinned
engine/integrations are installed. The plugin repository's optional
`tests/installed_profile.lua` checks plain `nvim` (default Ctrl and a Super
override) and both playground presets against this shared configuration;
headless testing explicitly emits `VeryLazy`, because it otherwise waits for
`UIEnter`. An additional controlled-PTY startup check confirms the real TUI
lifecycle loads the layer/pairs/which-key without manually emitting `VeryLazy`;
artifacts are under `/tmp/opencode/lazyvim-default-tui/`. Neither this nor decoded
keys prove physical key delivery or human visual behavior. Smoke-test children
disable ShaDa so scratch edits do not persist test registers/history.
There remain two engine-only buffered-input failures documented in
`~/work/lazyvim-vscode/docs/verification.md`; making this the requested default
does not resolve those blockers or establish daily-use acceptance.

## Reversibility

Use `nvim --clean` to bypass all configuration. To disable only the experimental
layer, add `enabled = false` to its spec in `lua/plugins/vscode.lua`, then restart;
LazyVim remains. Removing only the playground's two symlinks disables that entry
point, not default LazyVim. Keep the canonical `~/.config/nvim` available while
using the playground. Do not recursively delete data/state or restow unrelated work.
