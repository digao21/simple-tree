local window = require("simple-tree.infrastructure.window")

describe("SimpleTree user command", function()
	before_each(function()
		window.close()
		-- Load plugin definition
		require("simple-tree")
		dofile("plugin/simple-tree.lua")
	end)

	after_each(function()
		window.close()
	end)

	it("executes :SimpleTree open to open the explorer", function()
		assert.is_false(window.isOpen())

		vim.cmd("SimpleTree open")
		-- Wait for async scan and buffer render
		vim.wait(1000, function()
			return window.isOpen()
		end)

		assert.is_true(window.isOpen())
		assert.equals(window.getWin(), vim.api.nvim_get_current_win())
	end)

	it("executes :SimpleTree close to close the explorer", function()
		vim.cmd("SimpleTree open")
		vim.wait(1000, function()
			return window.isOpen()
		end)
		assert.is_true(window.isOpen())

		vim.cmd("SimpleTree close")
		assert.is_false(window.isOpen())
	end)

	it("executes :SimpleTree toggle to toggle the window state (AC-5)", function()
		assert.is_false(window.isOpen())

		-- Toggle open
		vim.cmd("SimpleTree toggle")
		vim.wait(1000, function()
			return window.isOpen()
		end)
		assert.is_true(window.isOpen())

		-- Toggle close
		vim.cmd("SimpleTree toggle")
		assert.is_false(window.isOpen())
	end)
end)
