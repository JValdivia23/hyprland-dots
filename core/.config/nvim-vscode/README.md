# Local LazyVim evaluation profile

Universal user configuration, independent of the hardware profile. Plain `nvim`
now loads LazyVim plus the local VS Code layer from `~/.config/nvim`. This entry
point reuses that configuration with separate plugin/data/state/cache paths.

- `nvim-vscode`: Super preset and a disposable playground.
- `nvim-vscode --ctrl`: Ctrl preset and playground, useful before Super forwarding is configured.
- `nvim-vscode --ctrl /path/to/file`: edit a file in the evaluation profile. The plugin is experimental; use disposable copies first.
- `NVIM_APPNAME=nvim-vscode nvim`: the same profile without the launcher/playground.
- `:VscodePlayground`: new scratch buffer; `:VscodeGuide`: the repository's verification checklist.

Default plugin checkout: `~/work/lazyvim-vscode`. Override with
`LAZYVIM_VSCODE_DIR=/absolute/path` (in Fish, use `env LAZYVIM_VSCODE_DIR=... nvim-vscode`).
The checkout is loaded directly, so source edits take effect after restarting
this profile. Edit `~/.config/nvim/lua/plugins/vscode.lua` to change wrapper options.
The default `nvim` preset is Ctrl; this playground retains its Super default.

LazyVim v16.0.1, lazy.nvim, Blink v1.10.2, mini.pairs, which-key and the engine
have explicit revisions. Other installed plugin revisions are recorded in
`~/.local/state/nvim-vscode/lazy-lock.json` (or the equivalent XDG state path).
Use `:Lazy restore` to restore the lockfile; change deliberate pins before
`:Lazy sync` when evaluating a new version. No periodic update checker is enabled.

Plugin downloads live in `~/.local/share/nvim-vscode`; cache/state likewise use
the `nvim-vscode` app name. No temporary `/tmp/opencode` dependency is required.
Language-server/formatter auto-install and automatic parser/toolchain builds
are disabled for this editing evaluation; enable them deliberately for a later
LSP/Tree-sitter compatibility pass. Other LazyVim integrations remain present.

## Physical input safety on the current Surface host

The live compositor intercepts Super+D (fullscreen), Super+K (keybindings),
Super+Z/Shift+Z (compositor history), and **Super+Shift+L (lock and suspend)**.
Do not press Super+Shift+L as a plugin test until that conflict is resolved.
This installation does not change Hyprland or Kitty mappings. The Ctrl preset
tests editing, not Super forwarding. Test directly, then in `herdr` if installed.

## Reversibility

Use `nvim` for the default LazyVim configuration or `nvim --clean` for stock
Neovim without the layer. The playground profile and launcher remain separate
symlinks into dotfiles `core/`; removing those two symlinks later disables only
this playground entry point without deleting its state/plugins. Keep the shared
`~/.config/nvim` source while using this playground. No shell alias, desktop
shortcut, or compositor binding is replaced.
