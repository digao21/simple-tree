local command = require("simple-tree.command")
local window = require("simple-tree.infrastructure.window")
local model = require("simple-tree.model")
local ui = require("simple-tree.ui")

describe("command module", function()
  before_each(function() window.close() end)

  after_each(function() window.close() end)

  it("opens the explorer window and executes callback", function()
    local done = false
    command.open(function() done = true end)

    vim.wait(1000, function() return done end)

    assert.is_true(done)
    assert.is_true(window.isOpen())
  end)

  it("closes the explorer window", function()
    local done = false
    command.open(function() done = true end)
    vim.wait(1000, function() return done end)
    assert.is_true(window.isOpen())

    command.close()
    assert.is_false(window.isOpen())
  end)

  it("toggles the explorer window", function()
    local done = false
    command.toggle(function() done = true end)
    vim.wait(1000, function() return done end)
    assert.is_true(window.isOpen())

    command.toggle()
    assert.is_false(window.isOpen())
  end)

  it("toggles a folder node and re-renders window", function()
    local root = {
      type = "directory",
      name = "root",
      path = "/root",
      childs = {
        {
          type = "directory",
          name = "src",
          path = "/root/src",
          childs = {
            {
              type = "file",
              name = "main.lua",
              path = "/root/src/main.lua",
            },
          },
        },
      },
    }

    model.setRoot(root)
    local initial_items = {
      { line = " root", id = 1 },
      { line = "   src", id = 2 },
    }
    window.open(initial_items)
    assert.is_true(window.isOpen())

    local buf = window.getBuf()
    local lines_before = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.same({ " root", "   src" }, lines_before)

    -- Toggle directory 'src' (ID 2)
    local done = false
    command.toggleFolder(2, function() done = true end)
    assert.is_true(done)

    local lines_after = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.same({ " root", "   src", "    main.lua" }, lines_after)

    -- Toggle back to collapse
    command.toggleFolder(2)
    local lines_collapsed = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.same({ " root", "   src" }, lines_collapsed)
  end)

  it("selectNode toggles directory when given directory node ID", function()
    local root = {
      type = "directory",
      name = "root",
      path = "/root",
      childs = {
        {
          type = "directory",
          name = "src",
          path = "/root/src",
          childs = {
            {
              type = "file",
              name = "main.lua",
              path = "/root/src/main.lua",
            },
          },
        },
      },
    }

    model.setRoot(root)
    window.open(ui.renderTree(model.getRoot()))

    local done = false
    command.selectNode(2, function() done = true end)
    assert.is_true(done)

    local buf = window.getBuf()
    assert.are.same({ " root", "   src", "    main.lua" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("selectNode opens file when given file node ID", function()
    local temp_file = vim.fn.tempname() .. "_cmd_test.lua"
    local fh = io.open(temp_file, "w")
    if fh then
      fh:write("-- test\n")
      fh:close()
    end

    local root = {
      type = "directory",
      name = "root",
      path = "/root",
      childs = {
        {
          type = "file",
          name = "cmd_test.lua",
          path = temp_file,
        },
      },
    }

    model.setRoot(root)
    local win = window.open(ui.renderTree(model.getRoot()))

    local done = false
    command.selectNode(2, function() done = true end)
    assert.is_true(done)

    local active_win = vim.api.nvim_get_current_win()
    assert.are_not.equal(win, active_win)
    assert.equals(temp_file, vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(active_win)))

    os.remove(temp_file)
    if vim.api.nvim_win_is_valid(active_win) then vim.api.nvim_win_close(active_win, true) end
  end)

  it("selectNode gracefully handles nil and nonexistent IDs", function()
    assert.has_no_errors(function()
      command.selectNode(nil)
      command.selectNode(9999)
    end)
  end)
end)
