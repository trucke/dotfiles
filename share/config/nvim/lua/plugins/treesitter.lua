local parsers = {
	"astro",
	"bash",
	"css",
	"diff",
	"dockerfile",
	"elixir",
	"git_config",
	"gitignore",
	"go",
	"gomod",
	"html",
	"javascript",
	"json",
	"lua",
	"luadoc",
	"make",
	"markdown",
	"markdown_inline",
	"printf",
	"query",
	"regex",
	"ruby",
	"sql",
	"ssh_config",
	"svelte",
	"tmux",
	"toml",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

local indent_filetypes = {
	css = true,
	go = true,
	html = true,
	javascript = true,
	json = true,
	jsonc = true,
	lua = true,
	query = true,
	ruby = true,
	svelte = true,
	toml = true,
	typescript = true,
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").install(parsers)

			local group = vim.api.nvim_create_augroup("treesitter-attach", { clear = true })

			---@param buf integer
			---@param language string
			local function treesitter_try_attach(buf, language)
				if not pcall(vim.treesitter.language.add, language) then
					return
				end

				if not pcall(vim.treesitter.start, buf, language) then
					return
				end

				if indent_filetypes[vim.bo[buf].filetype] then
					vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				callback = function(args)
					local language = vim.treesitter.language.get_lang(args.match)
					if not language then
						return
					end

					treesitter_try_attach(args.buf, language)
				end,
			})
		end,
	},
}

-- vim: ts=2 sts=2 sw=2 et
