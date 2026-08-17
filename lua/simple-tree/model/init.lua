local filesystem = require("simple-tree.model.filesystem")

local M = {}

---@type fun(root: Node|nil)[]
local subscribers = {}

--- Notifies all registered subscribers of the current model state.
local function notifySubscribers()
  local current_root = filesystem.getRoot()

  for _, subscriber in ipairs(subscribers) do
    subscriber(current_root)
  end
end

--- Sets the active tree root and notifies subscribers.
---@param new_root Node|nil
M.setRoot = function(new_root)
  filesystem.setRoot(new_root)
  notifySubscribers()
end

--- Returns a deep copy of the active root node.
---@return Node|nil
M.getRoot = filesystem.getRoot

--- Returns a deep copy of the node with the given ID.
---@param id number
---@return Node|nil
M.getNodeById = filesystem.getNodeById

--- Toggles the expansion state of a directory node and notifies subscribers on mutation.
---@param id number
---@return boolean success whether the node was a directory and state was toggled
M.toggleFolder = function(id)
  local toggled = filesystem.toggleFolder(id)
  if toggled then notifySubscribers() end
  return toggled
end

--- Registers a subscriber to be notified whenever the model changes.
---@param subscriber fun(root: Node|nil)
---@return fun() unsubscribe function
M.subscribe = function(subscriber)
  table.insert(subscribers, subscriber)
  return function() M.unsubscribe(subscriber) end
end

--- Alias for subscribe.
M.addSubscriber = M.subscribe

--- Unregisters a subscriber.
---@param subscriber fun(root: Node|nil)
M.unsubscribe = function(subscriber)
  for i, sub in ipairs(subscribers) do
    if sub == subscriber then
      table.remove(subscribers, i)
      break
    end
  end
end

--- Clears all subscribers (primarily for testing and state resets).
M.clearSubscribers = function() subscribers = {} end

return M
