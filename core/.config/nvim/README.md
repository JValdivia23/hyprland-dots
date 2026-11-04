# Default LazyVim + VS Code layer

`nvim` now loads **LazyVim as the base editor**, then the local `lazyvim-vscode`
plugin through the separate `lua/plugins/vscode.lua` spec. This is a universal
user configuration from dotfiles `core/`, exposed at `~/.config/nvim`; no shell
alias, wrapper named `nvim`, or compositor change is needed.

- `nvim`: normal LazyVim startup with the Ctrl preset for the experimental layer.
- `nvim /path/to/file`: edit normally; use disposable text for multicursor tests.
- `:VscodePlayground`: open scratch test text without writing a file.
- `:VscodeGuide`: open the repository's automatic/human verification checklist.
- `nvim-vscode --ctrl`: the same configuration in a separate data/state/cache
  namespace, opening a disposable playground by default.
- `nvim --clean`: bypass this configuration for a stock Neovim session.

## Configuration and updates

`lua/config/lazy.lua` bootstraps lazy.nvim and imports `lazyvim.plugins` before
the user plugin specs. `lua/plugins/baseline.lua` pins LazyVim v16.0.1 and the
tested integration versions. Language-server/formatter auto-install and parser
builds remain opt-in there during the experimental editing milestone; other
LazyVim integrations and leader mappings remain present.

`lua/plugins/vscode.lua` adds this plugin as a layer, without replacing LazyVim.
It defaults to `~/work/lazyvim-vscode`, or `LAZYVIM_VSCODE_DIR` if set. This live
checkout is loaded directly, so restart Neovim after source/config edits. Do not
initialize multicursor.nvim again in another spec.

Normal Neovim data/state/cache retain their usual `nvim` paths; the existing
`nvim-vscode` playground retains its own paths. Generated LazyVim metadata and
each profile's `lazy-lock.json` live under its XDG state directory, keeping
them out of the stowed configuration. Use `:Lazy restore` for the lockfile or
`:Lazy sync` after deliberately changing version pins. No update checker or
configuration hot-reload is enabled.

## Modifier safety and limitations

Plain `nvim` defaults to **Ctrl** because this host's compositor intercepts
Super+D/K/Z, and **Super+Shift+L locks and suspends**. Do not test that shortcut
until its collision is resolved separately. Change the preset in
`lua/plugins/vscode.lua`, or use `env LAZYVIM_VSCODE_PRESET=super nvim` only after
configuring forwarding. The plugin itself still defaults to Super elsewhere.
Ctrl+D replaces Normal/Visual half-page scrolling; Insert Ctrl+D/K remain native.

The layer is experimental, with two known upstream buffered-input bugs.
Physical keyboard/mouse and `herdr` verification remain pending. To temporarily
disable the layer, add `enabled = false` to its spec and restart; LazyVim remains.
To bypass all configuration without deleting anything, run `nvim --clean`.
