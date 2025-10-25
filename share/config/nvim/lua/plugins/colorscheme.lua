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
    config = function() vim.cmd.colorscheme 'tokyonight-moon' end,
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
  },
}

-- vim: ts=2 sts=2 sw=2 et
