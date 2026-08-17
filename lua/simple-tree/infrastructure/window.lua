local M = {}

---@type number|nil
local current_win = nil

---@type number|nil
local current_buf = nil

---@type table<number, number>
local current_line_to_id = {}

local DEFAULT_WIDTH = 30

local ns_id = vim.api.nvim_create_namespace("simple_tree_highlights")

--- Initializes default SimpleTree highlight groups linked to standard Neovim groups.
local function setupHighlights()
  vim.api.nvim_set_hl(0, "SimpleTreeDirectory", { default = true, link = "Directory" })
  vim.api.nvim_set_hl(0, "SimpleTreeFile", { default = true, link = "Normal" })
  vim.api.nvim_set_hl(0, "SimpleTreeFolderIcon", { default = true, link = "Directory" })
  vim.api.nvim_set_hl(0, "SimpleTreeIcon", { default = true, link = "Normal" })
end

setupHighlights()

--- Returns the namespace ID used for SimpleTree highlights.
---@return number
M.getNamespace = function() return ns_id end

--- Re-initializes SimpleTree default highlight groups.
M.setupHighlights = setupHighlights

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

--- Handles the select node keymap event (<CR>).
local function onSelectKey()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]
  local node_id = current_line_to_id[line_num]
  if node_id then
    local cmd = require("simple-tree.command")
    cmd.selectNode(node_id)
  end
end

--- Handles the folder toggle keymap event (<Space>).
local function onToggleKey()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]
  local node_id = current_line_to_id[line_num]
  if node_id then
    local cmd = require("simple-tree.command")
    cmd.toggleFolder(node_id)
  end
end

--- Opens a file in the window to the right of the SimpleTree sidebar,
--- creating a vertical split if no right window exists.
---@param file_path string
M.openFile = function(file_path)
  if not file_path or file_path == "" then return end

  if M.isOpen() and current_win then
    vim.api.nvim_set_current_win(current_win)
    vim.cmd("wincmd l")
    if vim.api.nvim_get_current_win() == current_win then
      vim.cmd("rightbelow vsplit")
      local new_win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_option_value("winfixbuf", false, { win = new_win })
      vim.api.nvim_set_option_value("winfixwidth", false, { win = new_win })
    end
  end

  vim.cmd("edit " .. vim.fn.fnameescape(file_path))
end

--- Applies extmarks defined on items to the given buffer.
---@param buf number
---@param items { line: string, id: number|nil, extmarks?: { col_start?: number, col_end?: number, highlight?: string, start_col?: number, end_col?: number, hl_group?: string }[] }[]
local function applyExtmarks(buf, items)
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  for line_idx, item in ipairs(items) do
    if item.extmarks then
      for _, mark in ipairs(item.extmarks) do
        local col_start = mark.col_start or mark.start_col or 0
        local col_end = mark.col_end or mark.end_col
        local hl_group = mark.highlight or mark.hl_group
        if col_end and hl_group then
          vim.api.nvim_buf_set_extmark(buf, ns_id, line_idx - 1, col_start, {
            end_col = col_end,
            hl_group = hl_group,
            hl_mode = "combine",
          })
        end
      end
    end
  end
end

--- Opens the explorer split window or refreshes it if already open.
---@param items { line: string, id: number|nil, extmarks?: { col_start?: number, col_end?: number, highlight?: string }[] }[]|nil
---@return number window ID
M.open = function(items)
  local lines = {}
  if items then
    current_line_to_id = {}
    for i, item in ipairs(items) do
      lines[i] = item.line
      if item.id ~= nil then current_line_to_id[i] = item.id end
    end
  end

  if M.isOpen() and current_win and current_buf then
    M.focus()
    if items then
      local cursor = vim.api.nvim_win_get_cursor(current_win)
      vim.api.nvim_set_option_value("modifiable", true, { buf = current_buf })
      vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)
      vim.api.nvim_set_option_value("modifiable", false, { buf = current_buf })

      applyExtmarks(current_buf, items)

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
  if #lines > 0 then vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines) end
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  if items and #items > 0 then applyExtmarks(buf, items) end

  -- Register buffer-local keybindings
  vim.keymap.set("n", "<CR>", onSelectKey, { buffer = buf, silent = true, nowait = true })
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
  vim.api.nvim_set_option_value("cursorline", true, { win = win })

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
  local buf_to_wipe = current_buf
  current_win = nil
  current_buf = nil
  current_line_to_id = {}

  if vim.api.nvim_win_is_valid(win_to_close) then
    local wins = vim.api.nvim_tabpage_list_wins(0)
    if #wins == 1 and wins[1] == win_to_close then
      vim.cmd("new")
      local new_win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_option_value("winfixbuf", false, { win = new_win })
      vim.api.nvim_set_option_value("winfixwidth", false, { win = new_win })
    end
    pcall(vim.api.nvim_win_close, win_to_close, true)
  end

  if buf_to_wipe and vim.api.nvim_buf_is_valid(buf_to_wipe) then
    pcall(vim.api.nvim_buf_delete, buf_to_wipe, { force = true })
  end
end

return M
