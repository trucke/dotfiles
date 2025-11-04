return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1001,
    opts = {},
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1001,
    opts = {},
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1001,
    opts = {},
  },
  {
    "rose-pine/neovim",
    name = 'rose-pine',
    lazy = false,
    priority = 1001,
    opts = {},
    config = function() vim.cmd.colorscheme 'rose-pine-moon' end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
