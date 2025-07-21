vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- vim.g.maplocalleader = '\\'

vim.g.have_nerd_font = true
vim.g.trouble_lualine = true
-- fix markdown indentation settings
vim.g.markdown_recommended_style = 0
vim.g.snacks_animate = false

vim.schedule(function() vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" end)
-- enable auto save/write
vim.o.autowrite = true
vim.o.backup = false
vim.o.colorcolumn = "110"
vim.o.completeopt = "menu,menuone,noselect"
-- hide * markup for bold and italic, but not markers w/ substitutions
vim.o.conceallevel = 2
vim.o.confirm = true
vim.o.cursorline = true
vim.o.expandtab = true
vim.o.ignorecase = true
vim.o.inccommand = "split"
vim.opt.isfname:append("@-@")
vim.o.jumpoptions = "view"
vim.o.laststatus = 3
vim.o.linebreak = true
vim.o.list = false
vim.o.number = true
vim.o.relativenumber = true
vim.o.scrolloff = 10
vim.o.shiftwidth = 4
vim.opt.shortmess:append({ W = true, I = true, C = true })
vim.o.showmode = false
vim.o.sidescrolloff = 8
vim.o.signcolumn = "yes"
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.smoothscroll = true
vim.o.softtabstop = 4
vim.o.splitbelow = true
vim.o.splitkeep = "screen"
vim.o.splitright = true
vim.o.swapfile = false
vim.o.tabstop = 4
vim.o.termguicolors = true
vim.o.timeoutlen = 300
vim.o.undodir = os.getenv("HOME") .. "/.local/share/nvim"
vim.o.undofile = true
vim.o.updatetime = 50

-- vim: ts=2 sts=2 sw=2 et
