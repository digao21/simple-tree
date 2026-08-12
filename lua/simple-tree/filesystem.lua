local util = require("simple-tree.util")

---@class Node
---@field type Filetype
---@field name string
---@field path string
---@field childs Node[] | nil

---@type Node
local root

local M = {}

---@param new_root Node
M.setRoot = function(new_root)
	root = new_root
end

M.getRoot = function()
	return util.deepCopy(root)
end

return M
