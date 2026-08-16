local command = require("simple-tree.command")
local window = require("simple-tree.infrastructure.window")
local filesystem = require("simple-tree.filesystem")

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

    filesystem.setRoot(root)
    local initial_lines = { " root", "   src" }
    window.open(initial_lines, { [1] = 1, [2] = 2 })
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
end)
