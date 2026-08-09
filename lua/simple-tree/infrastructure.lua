local uv = vim.uv or vim.loop

local DIR = "directory"

---@alias Filetype "file" | "directory" | "link" | "fifo" | "socket" | "char" | "block" | "unknown"

---@class Node
---@field type Filetype
---@field name string
---@field path string
---@field childs Node[] | nil

---@type table<Node, number>
local calls = {}

---@param path string
---@return string
local function getFilename(path)
  return vim.fn.fnamemodify(path, ":t")
end

---@param path string
---@param root Node
---@param node Node
---@param callback fun
local function _read_dir_async(path, root, node, callback)
  uv.fs_scandir(path, function(err, handle)
    if err or not handle then
      vim.schedule(function()
        calls[root] = calls[root]-1
        callback({}, err)
      end)

      return
    end

    local entries = {}
    while true do
      local name, type = uv.fs_scandir_next(handle)
      if not name or not type then break end

      local is_dir = type == DIR
      local new_path = path .. "/" .. name

      ---@type Node
      local child = {
        type = type,
        name = name,
        path = new_path,
        childs = (is_dir and {} or nil)
      }

      table.insert(node.childs, child)
      if is_dir then
        calls[root] = calls[root]+1
        _read_dir_async(new_path, root, child, callback)
      end
    end

    -- Return back to Neovim's main thread to safely update UI/buffers
    vim.schedule(function()
      calls[root] = calls[root]-1
      callback(entries, nil)
    end)
  end)
end

local function read_dir_async(path, callback)
  ---TODO: test if path is a directory

  ---@type Node
  local root = {
    type = DIR,
    name = getFilename(path),
    path = path,
    childs = {}
  }

  calls[root] = 1
  _read_dir_async(path, root, root, function()
    if calls[root] == 0 then
      calls[root] = nil
      callback(root)
    end
  end)
end

read_dir_async("/home/rodrigolm/git/buffer-list", function(entries, err)
  if (err) then
    vim.print("ERROR: " .. err)
  end

  vim.print(entries)
end)
