local repo = vim.env.LAZYVIM_VSCODE_DIR or vim.fn.expand("~/work/lazyvim-vscode")
assert(
  vim.fn.filereadable(repo .. "/lua/lazyvim-vscode/init.lua") == 1,
  "Set LAZYVIM_VSCODE_DIR to the local plugin checkout"
)
-- Plain nvim uses Ctrl until the host's Super collisions are resolved. The
-- separate playground retains its Super default and launcher preset switches.
local preset = vim.env.LAZYVIM_VSCODE_PRESET or (vim.env.NVIM_APPNAME == "nvim-vscode" and "super" or "ctrl")
assert(preset == "super" or preset == "ctrl", "LAZYVIM_VSCODE_PRESET must be super or ctrl")

return {
  {
    dir = repo,
    name = "lazyvim-vscode",
    import = "lazyvim-vscode.plugins",
    opts = { preset = preset, mouse = "alt", session_keys = false },
  },
}
