-- See `:help lspconfig-all` for a list of all the pre-configured LSPs
local servers = {
	bashls = {},
	elixirls = {},
	gopls = {
		settings = {
			gopls = {
				analyses = { unusedparams = true },
				staticcheck = true,
				usePlaceholders = true,
				completeUnimported = true, -- this enables auto-import
				gofumpt = true,
			},
		},
	},
	html = { filetypes = { "html", "templ" } },
	-- htmx = { filetypes = { "html", "templ" } },
	lua_ls = {
		settings = {
			Lua = {
				completion = { callSnippet = "Replace" },
				telemetry = { enable = false },
			},
		},
	},
	tailwindcss = {
		filetypes = { "templ", "astro", "javascript", "typescript", "svelte" },
		settings = { includeLanguages = { templ = "html" } },
	},
	templ = {},
	ts_ls = { settings = { inlay_hint = { enabled = true } } },
}

return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				{ path = "snacks.nvim", words = { "Snacks" } },
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("dev-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("<leader>cr", vim.lsp.buf.rename, "[R]ename")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
					map("<leader>clf", vim.lsp.buf.format, "[F]ormat the current buffer")
					map("K", vim.lsp.buf.hover, "Hover Documentation")
					map("<leader>ch", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
					end, "Toggle Inlay [H]ints")
				end,
			})

			-- Diagnostic Config
			vim.diagnostic.config({
				virtual_lines = true,
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
				underline = { severity = vim.diagnostic.severity.ERROR },
				signs = vim.g.have_nerd_font and {
					text = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					},
				} or {},
				virtual_text = {
					source = "if_many",
					spacing = 2,
					format = function(diagnostic)
						local diagnostic_message = {
							[vim.diagnostic.severity.ERROR] = diagnostic.message,
							[vim.diagnostic.severity.WARN] = diagnostic.message,
							[vim.diagnostic.severity.INFO] = diagnostic.message,
							[vim.diagnostic.severity.HINT] = diagnostic.message,
						}
						return diagnostic_message[diagnostic.severity]
					end,
				},
			})

			local capabilities = require("blink.cmp").get_lsp_capabilities()

			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, { "stylua" })
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				ensure_installed = {},
				automatic_installation = false,
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},
}

-- vim: ts=2 sts=2 sw=2 et
