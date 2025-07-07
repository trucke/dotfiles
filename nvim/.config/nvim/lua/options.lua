vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- vim.g.maplocalleader = '\\'

vim.g.have_nerd_font = true
vim.g.trouble_lualine = true
-- fix markdown indentation settings
vim.g.markdown_recommended_style = 0
vim.g.snacks_animate = false

vim.schedule(function() vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" end)
local opt = vim.opt
-- enable auto save/write
opt.autowrite = true
opt.backup = false
opt.colorcolumn = "110"
opt.completeopt = "menu,menuone,noselect"
-- hide * markup for bold and italic, but not markers w/ substitutions
opt.conceallevel = 2
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.ignorecase = true
opt.inccommand = "split"
opt.isfname:append("@-@")
opt.jumpoptions = "view"
opt.laststatus = 3
opt.linebreak = true
opt.list = false
opt.number = true
opt.relativenumber = true
opt.scrolloff = 10
opt.shiftwidth = 4
opt.shortmess:append({ W = true, I = true, C = true })
opt.showmode = false
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.smartcase = true
opt.smartindent = true
opt.smoothscroll = true
opt.softtabstop = 4
opt.splitbelow = true
opt.splitkeep = "screen"
opt.splitright = true
opt.swapfile = false
opt.tabstop = 4
opt.termguicolors = true
opt.timeoutlen = 300
opt.undodir = os.getenv("HOME") .. "/.local/share/nvim"
opt.undofile = true
opt.updatetime = 50

-- vim: ts=2 sts=2 sw=2 et
