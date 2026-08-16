local M = {}

--- Recursively creates a deep copy of a Node or table structure.
---@param node Node|nil
---@return Node|nil
local function deepCopy(node)
  if not node then return nil end

  local new_node = {}
  for key, value in pairs(node) do
    if key == "childs" and type(value) == "table" then
      new_node.childs = {}
      for _, child in ipairs(value) do
        table.insert(new_node.childs, deepCopy(child))
      end
    elseif type(value) == "table" then
      new_node[key] = deepCopy(value)
    else
      new_node[key] = value
    end
  end

  return new_node
end

M.deepCopy = deepCopy

return M
