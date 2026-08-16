local filesystem = require("simple-tree.filesystem")
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

    filesystem.setRoot(root)
    local items = ui.renderTree(filesystem.getRoot())
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

    filesystem.setRoot(root)
    local items = ui.renderTree(filesystem.getRoot())
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

  it("performs no-op when pressing <CR> on a file node (AC-3)", function()
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

    filesystem.setRoot(root)
    local items = ui.renderTree(filesystem.getRoot())
    local win = window.open(items)
    local buf = window.getBuf()

    -- Position cursor on line 2 ('README.md' file)
    vim.api.nvim_win_set_cursor(win, { 2, 0 })

    -- Press <CR>
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "tx", false)

    -- Verify unchanged buffer
    assert.are.same({
      " project",
      "  README.md",
    }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)
end)
