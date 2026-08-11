local fs = require("simple-tree.infrastructure.filesystem")
local ui = require("simple-tree.ui")

local M = {}

M.printFilesystem = function()
	local cwd = fs.get_cwd()
	fs.read_dir_async(cwd, function(root, errors)
		if errors then
			for _, err in ipairs(errors) do
				vim.print("ERROR: " .. err)
			end

			return
		end

		ui.printFilesystem(root)
	end)
end

return M
