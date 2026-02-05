-- Load colorscheme from ~/.config/theme/current/nvim-theme.lua
local function get_colorscheme()
  local theme_file = vim.fn.expand("~/.config/theme/current/nvim-theme.lua")
  local ok, colorscheme = pcall(dofile, theme_file)
  if ok and colorscheme then
    return colorscheme
  end
  return "rose-pine-moon" -- fallback
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1001,
    opts = {
      flavour = "mocha",
    },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1001,
    opts = {
      variant = "moon",
    },
    config = function(_, opts)
      require("rose-pine").setup(opts)
      vim.cmd.colorscheme(get_colorscheme())
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
