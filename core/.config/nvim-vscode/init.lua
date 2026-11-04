-- Same LazyVim + VS Code configuration, separate data/state/cache for evaluation.
assert(vim.env.NVIM_APPNAME == "nvim-vscode", "Launch with nvim-vscode or NVIM_APPNAME=nvim-vscode")
local config_home = vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config")
local shared = config_home .. "/nvim"
assert(
  vim.fn.filereadable(shared .. "/lua/config/lazy.lua") == 1,
  "Install the shared ~/.config/nvim configuration first"
)
vim.opt.rtp:prepend(shared)
require("config.lazy")
