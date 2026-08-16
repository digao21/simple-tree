local M = {}

---@type number|nil
local current_win = nil

---@type number|nil
local current_buf = nil

---@type table<number, number>
local current_line_to_id = {}

local DEFAULT_WIDTH = 30

--- Checks if the SimpleTree window is currently open and valid.
---@return boolean
M.isOpen = function() return current_win ~= nil and vim.api.nvim_win_is_valid(current_win) end

--- Returns the current window ID if open, nil otherwise.
---@return number|nil
M.getWin = function()
  if M.isOpen() then return current_win end
  return nil
end

--- Returns the current buffer ID if open, nil otherwise.
---@return number|nil
M.getBuf = function()
  if M.isOpen() then return current_buf end
  return nil
end

--- Returns the current line-to-ID mapping.
---@return table<number, number>
M.getLineToId = function() return current_line_to_id end

--- Focuses the SimpleTree window if currently open.
M.focus = function()
  if M.isOpen() and current_win then vim.api.nvim_set_current_win(current_win) end
end

--- Handles the folder toggle keymap event.
local function onToggleKey()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]
  local node_id = current_line_to_id[line_num]
  if node_id then
    local cmd = require("simple-tree.command")
    cmd.toggleFolder(node_id)
  end
end

--- Opens the explorer split window or refreshes it if already open.
---@param lines string[]|nil
---@param line_to_id table<number, number>|nil
---@return number window ID
M.open = function(lines, line_to_id)
  if line_to_id then current_line_to_id = line_to_id end

  if M.isOpen() and current_win and current_buf then
    M.focus()
    if lines then
      local cursor = vim.api.nvim_win_get_cursor(current_win)
      vim.api.nvim_set_option_value("modifiable", true, { buf = current_buf })
      vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)
      vim.api.nvim_set_option_value("modifiable", false, { buf = current_buf })

      -- Preserve and clamp cursor position
      local total_lines = #lines
      local row = math.min(cursor[1], math.max(1, total_lines))
      vim.api.nvim_win_set_cursor(current_win, { row, cursor[2] })
    end
    return current_win
  end

  -- Create scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buflisted", false, { buf = buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  vim.api.nvim_set_option_value("filetype", "simple-tree", { buf = buf })

  -- Populate buffer lines before making it unmodifiable
  if lines and #lines > 0 then vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines) end
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  -- Register buffer-local keybindings
  vim.keymap.set("n", "<CR>", onToggleKey, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("n", "<Space>", onToggleKey, { buffer = buf, silent = true, nowait = true })

  -- Open vertical split window anchored far left
  local win = vim.api.nvim_open_win(buf, true, {
    split = "left",
    win = -1,
    width = DEFAULT_WIDTH,
  })

  -- Apply window configuration options
  vim.api.nvim_set_option_value("winfixbuf", true, { win = win })
  vim.api.nvim_set_option_value("winfixwidth", true, { win = win })
  vim.api.nvim_set_option_value("number", false, { win = win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
  vim.api.nvim_set_option_value("foldcolumn", "0", { win = win })

  current_win = win
  current_buf = buf

  return win
end

--- Closes the explorer split window if open.
--- Gracefully does nothing if already closed.
M.close = function()
  if not M.isOpen() or not current_win then
    current_win = nil
    current_buf = nil
    current_line_to_id = {}
    return
  end

  local win_to_close = current_win
  current_win = nil
  current_buf = nil
  current_line_to_id = {}

  if vim.api.nvim_win_is_valid(win_to_close) then vim.api.nvim_win_close(win_to_close, true) end
end

return M
