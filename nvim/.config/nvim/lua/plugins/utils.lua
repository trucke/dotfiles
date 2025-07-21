return {
	{ "NMAC427/guess-indent.nvim" },
	{ "nvim-lua/plenary.nvim" },
	{
		"m4xshen/smartcolumn.nvim",
		opts = { colorcolumn = "110" },
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = {},
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
    opts = {},
		keys = {
			{"<leader>ss", function() require("telescope.builtin").live_grep() end, desc = "Dismiss All Notifications" },
		},
	},
}

-- vim: ts=2 sts=2 sw=2 et
