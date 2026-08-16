local util = require("simple-tree.util")

---@class Node
---@field id number
---@field type Filetype
---@field name string
---@field path string
---@field expanded boolean | nil
---@field childs Node[] | nil

---@type Node|nil
local root = nil

---@type table<number, Node>
local id_to_node = {}

--- Recursively indexes nodes with incremental unique IDs and populates id_to_node map.
---@param node Node
---@param next_id number
---@return number next_id
local function indexNodes(node, next_id)
  node.id = next_id
  id_to_node[node.id] = node
  next_id = next_id + 1

  if node.childs then
    for _, child in ipairs(node.childs) do
      next_id = indexNodes(child, next_id)
    end
  end

  return next_id
end

local M = {}

--- Sets the active tree root, assigning unique IDs and building lookup index.
---@param new_root Node|nil
M.setRoot = function(new_root)
  id_to_node = {}
  if not new_root then
    root = nil
    return
  end

  root = new_root
  if root.expanded == nil then root.expanded = true end

  indexNodes(root, 1)
end

--- Returns a deep copy of the active root node.
---@return Node|nil
M.getRoot = function() return util.deepCopy(root) end

--- Returns a deep copy of the node with the given ID.
---@param id number
---@return Node|nil
M.getNodeById = function(id)
  if id_to_node[id] then return util.deepCopy(id_to_node[id]) end
  return nil
end

--- Toggles the expansion state of a directory node.
---@param id number
---@return boolean success whether the node was a directory and state was toggled
M.toggleFolder = function(id)
  local node = id_to_node[id]
  if node and node.type == "directory" then
    node.expanded = (node.expanded ~= true)
    return true
  end
  return false
end

return M
