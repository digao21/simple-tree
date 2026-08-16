local M = {}

local FOLDER_ICON_CLOSED = ""
local FOLDER_ICON_OPEN = ""

M.FOLDER_ICON_CLOSED = FOLDER_ICON_CLOSED
M.FOLDER_ICON_CLOSE = FOLDER_ICON_CLOSED
M.FOLDER_ICON_OPEN = FOLDER_ICON_OPEN

local mini_icons_loaded, mini_icons = pcall(require, "mini.icons")
local devicons_loaded, devicons = pcall(require, "nvim-web-devicons")

--- Resolves the display icon and its highlight group for a given filesystem node.
---@param node Node
---@return string icon, string|nil hl_group
local function getIcon(node)
  if node.type == "directory" then
    if node.expanded then return FOLDER_ICON_OPEN, "SimpleTreeFolderIcon" end

    if mini_icons_loaded and mini_icons then
      local icon, hl = mini_icons.get("directory", node.name)
      if icon and icon ~= "" then return icon, hl or "SimpleTreeFolderIcon" end
    end

    return FOLDER_ICON_CLOSED, "SimpleTreeFolderIcon"
  end

  if mini_icons_loaded and mini_icons then
    local icon, hl = mini_icons.get("file", node.name)
    if icon and icon ~= "" then return icon, hl or "SimpleTreeIcon" end
  end

  if devicons_loaded and devicons then
    local icon, hl = devicons.get_icon(node.name)
    if icon and icon ~= "" then return icon, hl or "SimpleTreeIcon" end
  end

  return "", nil
end

--- Checks whether a node is hidden (name starts with a dot).
---@param node Node
---@return boolean
local function isHiddenNode(node) return node.name:sub(1, 1) == "." end

--- Compares two nodes: folders first, then alphabetically (case-insensitive).
---@param a Node
---@param b Node
---@return boolean
local function sortNodes(a, b)
  local a_is_dir = a.type == "directory"
  local b_is_dir = b.type == "directory"
  if a_is_dir ~= b_is_dir then return a_is_dir end
  return a.name:lower() < b.name:lower()
end

---@class Extmark
---@field col_start number
---@field col_end number
---@field highlight string

---@class TreeItem
---@field line string
---@field id number|nil
---@field extmarks Extmark[]

---@param node Node
---@param prefix string
---@param items TreeItem[]
local function renderNode(node, prefix, items)
  local icon, icon_hl = getIcon(node)
  local extmarks = {}
  local prefix_len = #prefix
  local line_text

  if icon and icon ~= "" then
    line_text = prefix .. icon .. " " .. node.name
    local icon_len = #icon
    table.insert(extmarks, {
      col_start = prefix_len,
      col_end = prefix_len + icon_len,
      highlight = icon_hl or (node.type == "directory" and "SimpleTreeFolderIcon" or "SimpleTreeIcon"),
    })

    local name_start = prefix_len + icon_len + 1
    local name_len = #node.name
    local name_hl = node.type == "directory" and "SimpleTreeDirectory" or "SimpleTreeFile"
    table.insert(extmarks, {
      col_start = name_start,
      col_end = name_start + name_len,
      highlight = name_hl,
    })
  else
    line_text = prefix .. node.name
    local name_start = prefix_len
    local name_len = #node.name
    local name_hl = node.type == "directory" and "SimpleTreeDirectory" or "SimpleTreeFile"
    table.insert(extmarks, {
      col_start = name_start,
      col_end = name_start + name_len,
      highlight = name_hl,
    })
  end

  table.insert(items, {
    line = line_text,
    id = node.id,
    extmarks = extmarks,
  })

  -- Only render descendants when the directory node is expanded
  if node.type == "directory" and node.expanded and node.childs then
    local visible_childs = {}
    for _, child in ipairs(node.childs) do
      if not isHiddenNode(child) then table.insert(visible_childs, child) end
    end

    table.sort(visible_childs, sortNodes)

    for _, child in ipairs(visible_childs) do
      renderNode(child, prefix .. "  ", items)
    end
  end
end

--- Transforms the in-memory tree state into a list of items, each with a line string, node ID, and extmarks.
---@param root Node|nil
---@return TreeItem[]
M.renderTree = function(root)
  if not root then return {} end

  local items = {}
  renderNode(root, "", items)
  return items
end

return M
