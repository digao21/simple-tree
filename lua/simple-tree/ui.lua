local M = {}

--- Checks whether a node is hidden (name starts with a dot).
---@param node Node
---@return boolean
local function isHiddenNode(node)
	return node.name:sub(1, 1) == "."
end

---@param node Node
---@param prefix string
---@param lines string[]
local function renderNode(node, prefix, lines)
	table.insert(lines, prefix .. node.name)
	if node.childs then
		for _, child in ipairs(node.childs) do
			if not isHiddenNode(child) then
				renderNode(child, prefix .. "  ", lines)
			end
		end
	end
end

--- Transforms the in-memory tree state into a list of display strings.
---@param root Node|nil
---@return string[]
M.renderTree = function(root)
	if not root then
		return {}
	end

	local lines = {}
	renderNode(root, "", lines)
	return lines
end

return M
