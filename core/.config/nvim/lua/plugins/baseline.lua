return {
  -- Known-tested LazyVim baseline; update pins deliberately, then :Lazy sync.
  { "folke/lazy.nvim", version = false, commit = "306a05526ada86a7b30af95c5cc81ffba93fef97" },
  {
    "LazyVim/LazyVim",
    version = false,
    commit = "999700997f72227187d49d8b92667183dc7fc809", -- v16.0.1
    opts = { news = { lazyvim = false, neovim = false } },
  },
  {
    "saghen/blink.cmp",
    version = false,
    commit = "78336bc89ee5365633bcf754d93df01678b5c08f", -- v1.10.2, tested integration API
    opts = { fuzzy = { implementation = "lua" } },
  },
  { "nvim-mini/mini.pairs", version = false, commit = "03eb1f0062a2cee5314d1ac3939246e4bb21352e" },
  { "folke/which-key.nvim", version = false, commit = "3aab2147e74890957785941f0c1ad87d0a44c15a" },
  -- Language tools and parser builds remain opt-in during the experimental
  -- editing milestone. Remove these overrides to enable LazyVim's auto-install.
  {
    "nvim-treesitter/nvim-treesitter",
    build = false,
    opts = function(_, opts)
      opts.ensure_installed = {}
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = {}
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      for name, server in pairs(opts.servers or {}) do
        if name ~= "*" and type(server) == "table" then
          server.enabled = false
        end
      end
    end,
  },
}
