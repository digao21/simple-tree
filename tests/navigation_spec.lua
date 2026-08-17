local model = require("simple-tree.model")
local ui = require("simple-tree.ui")
local window = require("simple-tree.infrastructure.window")

describe("navigation and folder toggling via keymaps", function()
  before_each(function() window.close() end)

  after_each(function() window.close() end)

  it("toggles directory expansion with <CR> (AC-1, AC-2)", function()
    local root = {
      type = "directory",
      name = "project",
      path = "/workspace/project",
      childs = {
        {
          type = "directory",
          name = "src",
          path = "/workspace/project/src",
          childs = {
            {
              type = "file",
              name = "main.lua",
              path = "/workspace/project/src/main.lua",
            },
          },
        },
        {
          type = "file",
          name = "README.md",
          path = "/workspace/project/README.md",
        },
      },
    }

    model.setRoot(root)
    local items = ui.renderTree(model.getRoot())
    local win = window.open(items)
    local buf = window.getBuf()

    assert.is_true(window.isOpen())
    assert.are.same({
      " project",
      "   src",
      "  README.md",
    }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))

    -- Position cursor on line 2 ('src' folder)
    vim.api.nvim_win_set_cursor(win, { 2, 0 })

    -- Press <CR> to expand 'src'
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "tx", false)

    -- Verify expanded buffer lines
    assert.are.same({
      " project",
      "   src",
      "    main.lua",
      "  README.md",
    }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))

    -- Press <CR> again to collapse 'src'
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "tx", false)

    -- Verify collapsed buffer lines
    assert.are.same({
      " project",
      "   src",
      "  README.md",
    }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("toggles directory expansion with <Space> (AC-1, AC-2)", function()
    local root = {
      type = "directory",
      name = "project",
      path = "/workspace/project",
      childs = {
        {
          type = "directory",
          name = "src",
          path = "/workspace/project/src",
          childs = {
            {
              type = "file",
              name = "main.lua",
              path = "/workspace/project/src/main.lua",
            },
          },
        },
      },
    }

    model.setRoot(root)
    local items = ui.renderTree(model.getRoot())
    local win = window.open(items)
    local buf = window.getBuf()

    -- Position cursor on line 2 ('src' folder)
    vim.api.nvim_win_set_cursor(win, { 2, 0 })

    -- Press <Space> to expand
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Space>", true, false, true), "tx", false)

    assert.are.same({
      " project",
      "   src",
      "    main.lua",
    }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))

    -- Press <Space> again to collapse
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Space>", true, false, true), "tx", false)

    assert.are.same({
      " project",
      "   src",
    }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("opens file in right window when pressing <CR> on a file node (AC-3)", function()
    local temp_file = vim.fn.tempname() .. "_test_file.lua"
    local file_handle = io.open(temp_file, "w")
    if file_handle then
      file_handle:write("print('hello world')\n")
      file_handle:close()
    end

    local root = {
      type = "directory",
      name = "project",
      path = "/workspace/project",
      childs = {
        {
          type = "file",
          name = "test_file.lua",
          path = temp_file,
        },
      },
    }

    model.setRoot(root)
    local items = ui.renderTree(model.getRoot())
    local win = window.open(items)

    -- Position cursor on line 2 ('test_file.lua' file)
    vim.api.nvim_win_set_cursor(win, { 2, 0 })

    -- Press <CR>
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "tx", false)

    -- Verify that current active window is now editing the target file
    local active_win = vim.api.nvim_get_current_win()
    assert.are_not.equal(win, active_win)

    local active_buf = vim.api.nvim_win_get_buf(active_win)
    local active_buf_name = vim.api.nvim_buf_get_name(active_buf)
    assert.equals(temp_file, active_buf_name)

    -- Clean up
    os.remove(temp_file)
    if vim.api.nvim_win_is_valid(active_win) then vim.api.nvim_win_close(active_win, true) end
  end)

  it("performs no-op when pressing <Space> on a file node (AC-4)", function()
    local root = {
      type = "directory",
      name = "project",
      path = "/workspace/project",
      childs = {
        {
          type = "file",
          name = "README.md",
          path = "/workspace/project/README.md",
        },
      },
    }

    model.setRoot(root)
    local items = ui.renderTree(model.getRoot())
    local win = window.open(items)
    local buf = window.getBuf()

    -- Position cursor on line 2 ('README.md' file)
    vim.api.nvim_win_set_cursor(win, { 2, 0 })

    -- Press <Space>
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Space>", true, false, true), "tx", false)

    -- Verify unchanged buffer and focus remains in tree
    assert.equals(win, vim.api.nvim_get_current_win())
    assert.are.same({
      " project",
      "  README.md",
    }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("opens file with spaces in filename in right window (AC-3)", function()
    local temp_file = vim.fn.tempname() .. " my special file.txt"
    local file_handle = io.open(temp_file, "w")
    if file_handle then
      file_handle:write("content with spaces\n")
      file_handle:close()
    end

    local root = {
      type = "directory",
      name = "project",
      path = "/workspace/project",
      childs = {
        {
          type = "file",
          name = "my special file.txt",
          path = temp_file,
        },
      },
    }

    model.setRoot(root)
    local items = ui.renderTree(model.getRoot())
    local win = window.open(items)

    -- Position cursor on line 2
    vim.api.nvim_win_set_cursor(win, { 2, 0 })

    -- Press <CR>
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "tx", false)

    local active_win = vim.api.nvim_get_current_win()
    assert.are_not.equal(win, active_win)
    assert.equals(temp_file, vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(active_win)))

    os.remove(temp_file)
    if vim.api.nvim_win_is_valid(active_win) then vim.api.nvim_win_close(active_win, true) end
  end)

  it("preserves relative visual hierarchy when navigating deeply nested structures (AC-5)", function()
    local root = {
      type = "directory",
      name = "project",
      path = "/workspace/project",
      childs = {
        {
          type = "directory",
          name = "level1",
          path = "/workspace/project/level1",
          childs = {
            {
              type = "directory",
              name = "level2",
              path = "/workspace/project/level1/level2",
              childs = {
                {
                  type = "file",
                  name = "deep.lua",
                  path = "/workspace/project/level1/level2/deep.lua",
                },
              },
            },
          },
        },
      },
    }

    model.setRoot(root)
    local items = ui.renderTree(model.getRoot())
    local win = window.open(items)
    local buf = window.getBuf()

    -- Expand level1
    vim.api.nvim_win_set_cursor(win, { 2, 0 })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "tx", false)

    -- Expand level2
    vim.api.nvim_win_set_cursor(win, { 3, 0 })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "tx", false)

    assert.are.same({
      " project",
      "   level1",
      "     level2",
      "      deep.lua",
    }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)
end)
