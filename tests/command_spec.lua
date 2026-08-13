local command = require("simple-tree.command")
local window = require("simple-tree.infrastructure.window")

describe("command module", function()
	before_each(function()
		window.close()
	end)

	after_each(function()
		window.close()
	end)

	it("opens the explorer window and executes callback", function()
		local done = false
		command.open(function()
			done = true
		end)

		vim.wait(1000, function()
			return done
		end)

		assert.is_true(done)
		assert.is_true(window.isOpen())
	end)

	it("closes the explorer window", function()
		local done = false
		command.open(function()
			done = true
		end)
		vim.wait(1000, function()
			return done
		end)
		assert.is_true(window.isOpen())

		command.close()
		assert.is_false(window.isOpen())
	end)

	it("toggles the explorer window", function()
		local done = false
		command.toggle(function()
			done = true
		end)
		vim.wait(1000, function()
			return done
		end)
		assert.is_true(window.isOpen())

		command.toggle()
		assert.is_false(window.isOpen())
	end)
end)
