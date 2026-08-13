local cmd = require("simple-tree.command")

local M = {}

--- Configures the SimpleTree plugin.
---@param _opts table|nil
M.setup = function(_opts)
	-- Placeholder for configuration table initialization
end

M.open = cmd.open
M.close = cmd.close
M.toggle = cmd.toggle

return M
