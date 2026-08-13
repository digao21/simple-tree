local window = require("simple-tree.infrastructure.window")

describe("infrastructure.window", function()
	before_each(function()
		-- Ensure clean state before each test
		window.close()
	end)

	after_each(function()
		window.close()
	end)

	it("AC-1 & 3.1 & 3.2: opens explorer window with required buffer and window attributes", function()
		local lines = { "project_root", "  main.lua", "  README.md" }
		local win = window.open(lines)

		assert.is_true(window.isOpen())
		assert.equals(win, window.getWin())
		assert.equals(win, vim.api.nvim_get_current_win())

		local buf = window.getBuf()
		assert.is_not_nil(buf)
		assert.is_true(vim.api.nvim_buf_is_valid(buf))

		-- Verify buffer characteristics
		assert.is_false(vim.api.nvim_get_option_value("buflisted", { buf = buf }))
		assert.equals("nofile", vim.api.nvim_get_option_value("buftype", { buf = buf }))
		assert.equals("wipe", vim.api.nvim_get_option_value("bufhidden", { buf = buf }))
		assert.is_false(vim.api.nvim_get_option_value("swapfile", { buf = buf }))
		assert.equals("simple-tree", vim.api.nvim_get_option_value("filetype", { buf = buf }))
		assert.is_false(vim.api.nvim_get_option_value("modifiable", { buf = buf }))

		-- Verify buffer content
		local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		assert.are.same(lines, buf_lines)

		-- Verify window characteristics
		assert.is_true(vim.api.nvim_get_option_value("winfixbuf", { win = win }))
		assert.is_true(vim.api.nvim_get_option_value("winfixwidth", { win = win }))
		assert.is_false(vim.api.nvim_get_option_value("number", { win = win }))
		assert.is_false(vim.api.nvim_get_option_value("relativenumber", { win = win }))
		assert.equals("no", vim.api.nvim_get_option_value("signcolumn", { win = win }))
		assert.equals("0", vim.api.nvim_get_option_value("foldcolumn", { win = win }))
	end)

	it("AC-2: shifts focus to existing window when already open", function()
		local win1 = window.open({ "root" })
		assert.equals(win1, vim.api.nvim_get_current_win())

		-- Create another window and shift focus to it
		vim.cmd("new")
		local edit_win = vim.api.nvim_get_current_win()
		assert.are_not.equal(win1, edit_win)

		-- Open again
		local win2 = window.open({ "root" })
		assert.equals(win1, win2)
		assert.equals(win1, vim.api.nvim_get_current_win())

		-- Clean up extra window
		if vim.api.nvim_win_is_valid(edit_win) then
			vim.api.nvim_win_close(edit_win, true)
		end
	end)

	it("AC-3: closes open explorer window and wipes buffer", function()
		local win = window.open({ "root" })
		local buf = window.getBuf()
		assert.is_true(window.isOpen())

		window.close()

		assert.is_false(window.isOpen())
		assert.is_nil(window.getWin())
		assert.is_nil(window.getBuf())
		assert.is_false(vim.api.nvim_win_is_valid(win))
		assert.is_false(vim.api.nvim_buf_is_valid(buf))
	end)

	it("AC-4: gracefully handles closing when already closed", function()
		assert.is_false(window.isOpen())
		assert.has_no_errors(function()
			window.close()
		end)
		assert.is_false(window.isOpen())
	end)

	it("AC-6: blocks buffer modifications due to modifiable=false", function()
		window.open({ "line1" })
		local buf = window.getBuf()

		assert.has_error(function()
			vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "modified text" })
		end)
	end)
end)
