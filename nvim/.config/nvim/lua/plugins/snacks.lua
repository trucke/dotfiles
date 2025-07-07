return {
	"folke/snacks.nvim",
	priority = 10000,
	lazy = false,
	---@type snacks.Config
	opts = {
		bigfile = { enabled = true },
		explorer = { enabled = true },
		input = { enabled = true },
		notifier = { enabled = true },
		picker = { enabled = true },
		quickfile = { enabled = true },
		statuscolumn = { enabled = false },
		zen = {},
	},
	keys = {
		{
			"<leader>n",
			function()
				---@diagnostic disable-next-line: undefined-field
				if Snacks.config.picker and Snacks.config.picker.enabled then
					Snacks.picker.notifications()
				else
					Snacks.notifier.show_history()
				end
			end,
			desc = "Notification History",
		},
		{ "<leader>nd", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
		-- explorer
		{ "<leader><leader>", function() Snacks.explorer() end, desc = "File Explorer" },
		{ "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
		{ "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
		-- search
		{ "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Search Keymaps" },
		{ "<leader>sh", function() Snacks.picker.help() end, desc = "Search Help" },
		{ "<leader>su", function() Snacks.picker.undo() end, desc = "Search Undo History" },
		{ "<leader>sc", function() Snacks.picker.colorschemes() end, desc = "Search Colorschemes" },
		{ "<leader>sb", function() Snacks.picker.buffers() end, desc = "Search Buffers" },
		{ "<leader>sf", function() Snacks.picker.files({ hidden = true }) end, desc = "Search Files" },
		{ "<leader>sgf", function() Snacks.picker.git_files() end, desc = "Search Git Files" },
		{ "<leader>/", function() Snacks.picker.grep() end, desc = "Search string" },
		{
			"<leader>sn",
			function()
				Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "Search Neovim config",
		},
		-- git
		{ "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git Branches" },
		{ "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
		{ "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
		{ "<leader>gL", function() Snacks.picker.git_log() end, desc = "Git Log" },
		-- LSP
		{ "cgd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
		{ "cgD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
		{ "cgr", function() Snacks.picker.lsp_references() end, desc = "Goto Reference" },
		{ "cgi", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
		{ "cgt", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto Type Defenition" },
		{ "cgO", function() Snacks.picker.lsp_symbols() end, desc = "Open Document Symbols" },
		-- Zen mode
		{ "<leader>z", function() Snacks.zen() end, desc = "Toggle Zen Mode" },
	},
  init = function()
	vim.api.nvim_create_autocmd("LspProgress", {
		callback = function(ev)
			local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
			vim.notify(vim.lsp.status(), vim.log.levels.INFO, {
				id = "lsp_progress",
				title = "LSP Progress",
				opts = function(notif)
					notif.icon = ev.data.params.value.kind == "end" and " "
						or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
				end,
			})
		end,
	})
  end,
	config = function(_, opts)
		local notify = vim.notify
		require("snacks").setup(opts)
		if require("lazy.core.config").spec.plugins["noice.nvim"] then
			vim.notify = notify
		end
	end,
}

-- vim: ts=2 sts=2 sw=2 et
