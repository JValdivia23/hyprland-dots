local M = {}

function M.open()
  local wrapper = package.loaded["lazyvim-vscode.multicursor"]
  if wrapper then
    wrapper.clear()
  end
  vim.cmd.enew()
  local buffer = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buffer, "vscode-playground-" .. buffer)
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.undofile = false
  vim.bo.filetype = "text"
  local preset = LazyVim.opts("lazyvim-vscode").preset
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
    "foo foobar foo",
    "café café café",
    "alpha beta alpha beta alpha",
    "",
    "LazyVim + local lazyvim-vscode | preset: " .. preset,
    "Experimental: two known upstream buffered-input bugs remain. Use disposable text.",
    "",
    "1. On the first foo: press select-next twice; foobar must be skipped.",
    "2. Press c, type bar, Escape; both selected foo ranges should change.",
    "3. Native u / Ctrl+r undo and redo; Escape in Normal collapses cursors.",
    "4. From Insert, Super select-next enters Select mode; typing replaces text.",
    "5. Alt-click toggles cursors; Alt-drag adds vertical cursors in Normal mode.",
    "",
    "Super preset: Super+d; skip Super+k then Super+d; all Super+Shift+l.",
    "Ctrl preset: Ctrl+d; skip Ctrl+k then Ctrl+d; all Ctrl+k then l.",
    "History: preset+z / preset+Shift+z. Ctrl preset preserves Insert Ctrl+d/Ctrl+k.",
    "",
    "IMPORTANT: check compositor bindings before Super testing. A chord may lock/suspend.",
    "Launch nvim-vscode --ctrl to evaluate editing without claiming Super passthrough.",
    "",
    ":VscodePlayground opens fresh scratch text. :VscodeGuide opens the checklist.",
    "Exit with :qa! | No file is written by editing this buffer.",
  })
  vim.bo.modified = false
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

return M
