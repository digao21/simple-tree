local M = {}

---@param prefix string
---@param node Node
local function _printNode(prefix, node)
	vim.print(prefix .. node.name)
	if node.childs then
		for _, child in ipairs(node.childs) do
			_printNode(prefix .. "  ", child)
		end
	end
end

---@param root Node
M.printFilesystem = function(root)
	_printNode("", root)
end

return M
