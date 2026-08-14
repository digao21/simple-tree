local M = {}

local FOLDER_ICON_CLOSED = ""
local FOLDER_ICON_OPEN = ""

M.FOLDER_ICON_CLOSED = FOLDER_ICON_CLOSED
M.FOLDER_ICON_CLOSE = FOLDER_ICON_CLOSED
M.FOLDER_ICON_OPEN = FOLDER_ICON_OPEN

local mini_icons_loaded, mini_icons = pcall(require, "mini.icons")
local devicons_loaded, devicons = pcall(require, "nvim-web-devicons")

--- Resolves the display icon for a given filesystem node.
---@param node Node
---@return string
local function getIcon(node)
	if node.type == "directory" then
		if node.expanded then
			return FOLDER_ICON_OPEN
		end

		if mini_icons_loaded and mini_icons then
			local icon = mini_icons.get("directory", node.name)
			if icon and icon ~= "" then
				return icon
			end
		end

		return FOLDER_ICON_CLOSED
	end

	if mini_icons_loaded and mini_icons then
		local icon = mini_icons.get("file", node.name)
		if icon and icon ~= "" then
			return icon
		end
	end

	if devicons_loaded and devicons then
		return devicons.get_icon(node.name) or ""
	end

	return ""
end

--- Checks whether a node is hidden (name starts with a dot).
---@param node Node
---@return boolean
local function isHiddenNode(node)
	return node.name:sub(1, 1) == "."
end

--- Compares two nodes: folders first, then alphabetically (case-insensitive).
---@param a Node
---@param b Node
---@return boolean
local function sortNodes(a, b)
	local a_is_dir = a.type == "directory"
	local b_is_dir = b.type == "directory"
	if a_is_dir ~= b_is_dir then
		return a_is_dir
	end
	return a.name:lower() < b.name:lower()
end

---@param node Node
---@param prefix string
---@param lines string[]
---@param line_to_id table<number, number>
local function renderNode(node, prefix, lines, line_to_id)
	local icon = getIcon(node)

	local name = node.name
	if icon and icon ~= "" then
		name = icon .. " " .. name
	end

	table.insert(lines, prefix .. name)
	if node.id then
		line_to_id[#lines] = node.id
	end

	-- Only render descendants when the directory node is expanded
	if node.type == "directory" and node.expanded and node.childs then
		local visible_childs = {}
		for _, child in ipairs(node.childs) do
			if not isHiddenNode(child) then
				table.insert(visible_childs, child)
			end
		end

		table.sort(visible_childs, sortNodes)

		for _, child in ipairs(visible_childs) do
			renderNode(child, prefix .. "  ", lines, line_to_id)
		end
	end
end

--- Transforms the in-memory tree state into a list of display strings and a line-to-ID map.
---@param root Node|nil
---@return string[] lines, table<number, number> line_to_id
M.renderTree = function(root)
	if not root then
		return {}, {}
	end

	local lines = {}
	local line_to_id = {}
	renderNode(root, "", lines, line_to_id)
	return lines, line_to_id
end

return M
