return {
	"stevearc/oil.nvim",
	lazy = false,
	opts = {
		default_file_explorer = true,
		columns = { "icon" },
		skip_confirm_for_simple_edits = true,
		float = {
			max_width = 90,
			max_height = 30,
		},
		view_options = { show_hidden = true },
		win_options = {
			signcolumn = "yes",
		},
		preview_win = {
			win_options = { wrap = false },
		},
	},
	keys = {
		{ "<leader>e", function() require("oil").open(nil, { preview = {} }) end, desc = "Open file explorer" },
		{ "<leader>o", function() require("oil").toggle_float() end, desc = "Open file explorer (floating)" },
	},
}

-- vim: ts=2 sts=2 sw=2 et
