return {
	{
		"folke/trouble.nvim",
		opts = {
			modes = { lsp = { win = { position = "right" } } },
		},
		keys = {
			{ "<leader>xd", ":Trouble diagnostics toggle<CR>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xq", ":Trouble qflist toggle<CR>", desc = "Quickfix List (Trouble)" },
		},
	},
	{
		"folke/todo-comments.nvim",
		opts = {
			signs = false,
			highlight = { keyword = "fg" },
		},
		keys = {
			---@diagnostic disable-next-line: undefined-field
			{ "<leader>xt", function() Snacks.picker.todo_comments() end, desc = "Todo" },
			{
				"<leader>xT",
				---@diagnostic disable-next-line: undefined-field
				function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end,
				desc = "Todo/Fix/Fixme",
			},
		},
	},
}

-- vim: ts=2 sts=2 sw=2 et
