assert(vim.fn.has("nvim-0.12") == 1, "This LazyVim configuration requires Neovim 0.12+")
local config_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")

local state = vim.fn.stdpath("state")
vim.fn.mkdir(state, "p")
-- Keep generated metadata out of the stowed configuration source.
vim.g.lazyvim_json = state .. "/lazyvim.json"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local revision = "306a05526ada86a7b30af95c5cc81ffba93fef97"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local output =
    vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
  assert(vim.v.shell_error == 0, "lazy.nvim clone failed:\n" .. output)
  output = vim.fn.system({ "git", "-C", lazypath, "checkout", "--detach", revision })
  assert(vim.v.shell_error == 0, "lazy.nvim checkout failed:\n" .. output)
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  defaults = { lazy = false, version = false },
  lockfile = state .. "/lazy-lock.json",
  checker = { enabled = false },
  -- Restart after config edits; do not hot-reload the experimental input engine.
  change_detection = { enabled = false, notify = false },
  performance = {
    rtp = {
      -- lazy.nvim resets runtimepath; retain shared modules for nvim-vscode too.
      paths = { config_root, config_root .. "/after" },
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})

vim.api.nvim_create_user_command("VscodePlayground", function()
  require("config.playground").open()
end, { desc = "Open a disposable multicursor evaluation buffer" })

vim.api.nvim_create_user_command("VscodeGuide", function()
  local repo = vim.env.LAZYVIM_VSCODE_DIR or vim.fn.expand("~/work/lazyvim-vscode")
  vim.cmd.edit(vim.fn.fnameescape(repo .. "/docs/verification.md"))
end, { desc = "Open the automatic/human verification checklist" })
