local window = require("simple-tree.infrastructure.window")

describe("infrastructure.window", function()
  before_each(function()
    -- Ensure clean state before each test
    window.close()
  end)

  after_each(function() window.close() end)

  it("AC-1 & 3.1 & 3.2: opens explorer window with required buffer and window attributes", function()
    local items = {
      { line = "project_root", id = 1 },
      { line = "  main.lua", id = 2 },
      { line = "  README.md", id = 3 },
    }
    local win = window.open(items)

    assert.is_true(window.isOpen())
    assert.equals(win, window.getWin())
    assert.equals(win, vim.api.nvim_get_current_win())

    local buf = window.getBuf()
    assert.is_not_nil(buf)
    assert.is_true(vim.api.nvim_buf_is_valid(buf))

    -- Verify buffer characteristics
    assert.is_false(vim.api.nvim_get_option_value("buflisted", { buf = buf }))
    assert.equals("nofile", vim.api.nvim_get_option_value("buftype", { buf = buf }))
    assert.equals("wipe", vim.api.nvim_get_option_value("bufhidden", { buf = buf }))
    assert.is_false(vim.api.nvim_get_option_value("swapfile", { buf = buf }))
    assert.equals("simple-tree", vim.api.nvim_get_option_value("filetype", { buf = buf }))
    assert.is_false(vim.api.nvim_get_option_value("modifiable", { buf = buf }))

    -- Verify buffer content
    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.same({ "project_root", "  main.lua", "  README.md" }, buf_lines)
    assert.are.same({ [1] = 1, [2] = 2, [3] = 3 }, window.getLineToId())

    -- Verify window characteristics
    assert.is_true(vim.api.nvim_get_option_value("winfixbuf", { win = win }))
    assert.is_true(vim.api.nvim_get_option_value("winfixwidth", { win = win }))
    assert.is_true(vim.api.nvim_get_option_value("cursorline", { win = win }))
    assert.is_false(vim.api.nvim_get_option_value("number", { win = win }))
    assert.is_false(vim.api.nvim_get_option_value("relativenumber", { win = win }))
    assert.equals("no", vim.api.nvim_get_option_value("signcolumn", { win = win }))
    assert.equals("0", vim.api.nvim_get_option_value("foldcolumn", { win = win }))
  end)

  it("AC-7: enables cursorline highlighting inside the simple-tree window", function()
    local win = window.open({ { line = "root", id = 1 } })
    assert.is_true(vim.api.nvim_get_option_value("cursorline", { win = win }))
  end)

  it("AC-2: shifts focus to existing window when already open", function()
    local win1 = window.open({ { line = "root", id = 1 } })
    assert.equals(win1, vim.api.nvim_get_current_win())

    -- Create another window and shift focus to it
    vim.cmd("new")
    local edit_win = vim.api.nvim_get_current_win()
    assert.are_not.equal(win1, edit_win)

    -- Open again
    local win2 = window.open({ { line = "root", id = 1 } })
    assert.equals(win1, win2)
    assert.equals(win1, vim.api.nvim_get_current_win())

    -- Clean up extra window
    if vim.api.nvim_win_is_valid(edit_win) then vim.api.nvim_win_close(edit_win, true) end
  end)

  it("AC-3: closes open explorer window and wipes buffer", function()
    local win = window.open({ { line = "root", id = 1 } })
    local buf = window.getBuf()
    assert.is_true(window.isOpen())

    window.close()

    assert.is_false(window.isOpen())
    assert.is_nil(window.getWin())
    assert.is_nil(window.getBuf())
    assert.are.same({}, window.getLineToId())
    assert.is_false(vim.api.nvim_win_is_valid(win))
    assert.is_false(vim.api.nvim_buf_is_valid(buf))
  end)

  it("AC-4: gracefully handles closing when already closed", function()
    assert.is_false(window.isOpen())
    assert.has_no_errors(function() window.close() end)
    assert.is_false(window.isOpen())
  end)

  it("AC-6: blocks buffer modifications due to modifiable=false", function()
    window.open({ { line = "line1", id = 1 } })
    local buf = window.getBuf()

    assert.has_error(function() vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "modified text" }) end)
  end)

  it("handles items without id without adding entry to line_to_id map", function()
    window.open({ { line = "line_no_id", id = nil } })
    assert.are.same({}, window.getLineToId())
  end)

  it("handles window.open with nil and empty items", function()
    local win = window.open(nil)
    assert.is_true(window.isOpen())
    assert.equals(win, window.getWin())
    assert.are.same({}, window.getLineToId())
  end)

  it("exposes a valid namespace and initializes default highlight groups", function()
    local ns = window.getNamespace()
    assert.is_number(ns)
    assert.is_true(ns > 0)

    local hl_dir = vim.api.nvim_get_hl(0, { name = "SimpleTreeDirectory" })
    assert.is_table(hl_dir)
    assert.equals("Directory", hl_dir.link)

    local hl_file = vim.api.nvim_get_hl(0, { name = "SimpleTreeFile" })
    assert.is_table(hl_file)
    assert.equals("Normal", hl_file.link)

    local hl_folder_icon = vim.api.nvim_get_hl(0, { name = "SimpleTreeFolderIcon" })
    assert.is_table(hl_folder_icon)
    assert.equals("Directory", hl_folder_icon.link)

    local hl_icon = vim.api.nvim_get_hl(0, { name = "SimpleTreeIcon" })
    assert.is_table(hl_icon)
    assert.equals("Normal", hl_icon.link)
  end)

  it("applies extmarks to buffer and updates them upon refresh", function()
    local items = {
      {
        line = " project",
        id = 1,
        extmarks = {
          { col_start = 0, col_end = 3, highlight = "SimpleTreeFolderIcon" },
          { col_start = 4, col_end = 11, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "  main.lua",
        id = 2,
        extmarks = {
          { col_start = 2, col_end = 10, highlight = "SimpleTreeFile" },
        },
      },
    }

    window.open(items)
    local buf = window.getBuf()
    local ns = window.getNamespace()

    local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
    assert.equals(3, #marks)

    -- First extmark: line 0, col 0..3, SimpleTreeFolderIcon
    assert.equals(0, marks[1][2]) -- row
    assert.equals(0, marks[1][3]) -- col
    assert.equals(3, marks[1][4].end_col)
    assert.equals("SimpleTreeFolderIcon", marks[1][4].hl_group)

    -- Second extmark: line 0, col 4..11, SimpleTreeDirectory
    assert.equals(0, marks[2][2])
    assert.equals(4, marks[2][3])
    assert.equals(11, marks[2][4].end_col)
    assert.equals("SimpleTreeDirectory", marks[2][4].hl_group)

    -- Third extmark: line 1, col 2..10, SimpleTreeFile
    assert.equals(1, marks[3][2])
    assert.equals(2, marks[3][3])
    assert.equals(10, marks[3][4].end_col)
    assert.equals("SimpleTreeFile", marks[3][4].hl_group)

    -- Re-render / refresh with updated items
    local refreshed_items = {
      {
        line = " project",
        id = 1,
        extmarks = {
          { col_start = 0, col_end = 3, highlight = "SimpleTreeFolderIcon" },
          { col_start = 4, col_end = 11, highlight = "SimpleTreeDirectory" },
        },
      },
    }

    window.open(refreshed_items)
    local marks_refreshed = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
    assert.equals(2, #marks_refreshed)
    assert.equals(0, marks_refreshed[1][2])
    assert.equals(0, marks_refreshed[1][3])
    assert.equals(3, marks_refreshed[1][4].end_col)
    assert.equals("SimpleTreeFolderIcon", marks_refreshed[1][4].hl_group)
    assert.equals(0, marks_refreshed[2][2])
    assert.equals(4, marks_refreshed[2][3])
    assert.equals(11, marks_refreshed[2][4].end_col)
    assert.equals("SimpleTreeDirectory", marks_refreshed[2][4].hl_group)
  end)
end)
