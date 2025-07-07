return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown", "Avante" },
		opts = {
			checkbox = {
				custom = {
					todo = { rendered = "◯ " },
					delayed = { raw = "[~]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
				},
			},
			completions = { blink = { enabled = true } },
			file_types = { "markdown", "Avante" },
			heading = { position = "inline" },
			latex = { enabled = false },
			quote = { repeat_linebreak = true },
			sign = { enabled = false },
			pipe_table = { min_width = 15, alignment_indicator = "┅" },
		},
		keys = {
			{ "<leader>mt", ":RenderMarkdown toggle<CR>", desc = "Markdown Toggle Renderer" },
		},
	},
	{
		"toppair/peek.nvim",
		event = { "VeryLazy" },
		build = "deno task --quiet build:fast",
		opts = { theme = "dark" },
		keys = {
			{
				"<leader>mp",
				function()
					if require("peek").is_open() then
						require("peek").close()
					else
						require("peek").open()
					end
				end,
				desc = "Open Markdown Preview",
			},
		},
	},
}

-- vim: ts=2 sts=2 sw=2 et
