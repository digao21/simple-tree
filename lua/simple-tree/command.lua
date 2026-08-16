local fs = require("simple-tree.infrastructure.filesystem")
local window = require("simple-tree.infrastructure.window")
local filesystem = require("simple-tree.filesystem")
local ui = require("simple-tree.ui")

local M = {}

--- Opens the SimpleTree explorer window.
--- If already open, shifts focus to the existing window.
---@param callback fun()|nil Optional completion callback
M.open = function(callback)
  if window.isOpen() then
    window.focus()
    if callback then callback() end
    return
  end

  local cwd = fs.get_cwd()
  fs.read_dir_async(cwd, function(root, _errors)
    filesystem.setRoot(root)
    local lines, line_to_id = ui.renderTree(filesystem.getRoot())
    window.open(lines, line_to_id)
    if callback then callback() end
  end)
end

--- Closes the SimpleTree explorer window if open.
M.close = function() window.close() end

--- Toggles the SimpleTree explorer window.
---@param callback fun()|nil Optional completion callback
M.toggle = function(callback)
  if window.isOpen() then
    M.close()
    if callback then callback() end
  else
    M.open(callback)
  end
end

--- Toggles expansion of a folder node and re-renders the explorer window.
---@param node_id number
---@param callback fun()|nil Optional completion callback
M.toggleFolder = function(node_id, callback)
  if not node_id then return end

  local toggled = filesystem.toggleFolder(node_id)
  if toggled then
    local root = filesystem.getRoot()
    local lines, line_to_id = ui.renderTree(root)
    window.open(lines, line_to_id)
  end

  if callback then callback() end
end

return M
