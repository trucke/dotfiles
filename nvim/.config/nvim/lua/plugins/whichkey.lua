return {
	"folke/which-key.nvim",
	event = "VimEnter",
	opts = {
		preset = "helix",
		spec = {
			mode = { "n", "v" },
			{ "<leader>c", group = "code" },
			{ "<leader>g", group = "git" },
			{ "<leader>m", group = "markdown" },
			{ "<leader>s", group = "search" },
			{ "<leader>x", group = "diagnostics" },
			{ "cg", group = "goto" },
		},
	},
	keys = {
		{
			"<c-x>",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
}

-- vim: ts=2 sts=2 sw=2 et
