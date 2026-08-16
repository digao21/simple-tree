local ui = require("simple-tree.ui")

describe("ui.renderTree", function()
  it("exposes folder icon constants and aliases", function()
    assert.equals("", ui.FOLDER_ICON_CLOSED)
    assert.equals("", ui.FOLDER_ICON_CLOSE)
    assert.equals("", ui.FOLDER_ICON_OPEN)
  end)

  it("returns empty list when root is nil", function()
    local items = ui.renderTree(nil)
    assert.are.same({}, items)
  end)

  it("renders a single root node with default closed folder icon, id, and extmarks", function()
    local root = {
      id = 1,
      type = "directory",
      name = "my_project",
      path = "/path/to/my_project",
      expanded = false,
    }

    local items = ui.renderTree(root)
    assert.are.same({
      {
        line = " my_project",
        id = 1,
        extmarks = {
          { col_start = 0, col_end = 3, highlight = "SimpleTreeFolderIcon" },
          { col_start = 4, col_end = 14, highlight = "SimpleTreeDirectory" },
        },
      },
    }, items)
  end)

  it("renders an expanded root folder with FOLDER_ICON_OPEN and its children", function()
    local root = {
      id = 1,
      type = "directory",
      name = "my_project",
      path = "/path/to/my_project",
      expanded = true,
      childs = {
        {
          id = 2,
          type = "file",
          name = "init.lua",
          path = "/path/to/my_project/init.lua",
        },
      },
    }

    local items = ui.renderTree(root)
    assert.are.same({
      {
        line = " my_project",
        id = 1,
        extmarks = {
          { col_start = 0, col_end = 3, highlight = "SimpleTreeFolderIcon" },
          { col_start = 4, col_end = 14, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "  init.lua",
        id = 2,
        extmarks = {
          { col_start = 2, col_end = 10, highlight = "SimpleTreeFile" },
        },
      },
    }, items)
  end)

  it("does not render children of collapsed directory nodes", function()
    local root = {
      id = 1,
      type = "directory",
      name = "my_project",
      path = "/path/to/my_project",
      expanded = false,
      childs = {
        {
          id = 2,
          type = "file",
          name = "init.lua",
          path = "/path/to/my_project/init.lua",
        },
      },
    }

    local items = ui.renderTree(root)
    assert.are.same({
      {
        line = " my_project",
        id = 1,
        extmarks = {
          { col_start = 0, col_end = 3, highlight = "SimpleTreeFolderIcon" },
          { col_start = 4, col_end = 14, highlight = "SimpleTreeDirectory" },
        },
      },
    }, items)
  end)

  it("renders deeply nested hierarchies with proper level indentation and mixed expansion states", function()
    local root = {
      id = 1,
      type = "directory",
      name = "root",
      path = "/root",
      expanded = true,
      childs = {
        {
          id = 2,
          type = "directory",
          name = "src",
          path = "/root/src",
          expanded = true,
          childs = {
            {
              id = 3,
              type = "directory",
              name = "core",
              path = "/root/src/core",
              expanded = false, -- Collapsed: engine.lua should NOT be rendered
              childs = {
                {
                  id = 4,
                  type = "file",
                  name = "engine.lua",
                  path = "/root/src/core/engine.lua",
                },
              },
            },
            {
              id = 5,
              type = "file",
              name = "main.lua",
              path = "/root/src/main.lua",
            },
          },
        },
        {
          id = 6,
          type = "file",
          name = "package.json",
          path = "/root/package.json",
        },
      },
    }

    local items = ui.renderTree(root)
    assert.are.same({
      {
        line = " root",
        id = 1,
        extmarks = {
          { col_start = 0, col_end = 3, highlight = "SimpleTreeFolderIcon" },
          { col_start = 4, col_end = 8, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "   src",
        id = 2,
        extmarks = {
          { col_start = 2, col_end = 5, highlight = "SimpleTreeFolderIcon" },
          { col_start = 6, col_end = 9, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "     core",
        id = 3,
        extmarks = {
          { col_start = 4, col_end = 7, highlight = "SimpleTreeFolderIcon" },
          { col_start = 8, col_end = 12, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "    main.lua",
        id = 5,
        extmarks = {
          { col_start = 4, col_end = 12, highlight = "SimpleTreeFile" },
        },
      },
      {
        line = "  package.json",
        id = 6,
        extmarks = {
          { col_start = 2, col_end = 14, highlight = "SimpleTreeFile" },
        },
      },
    }, items)
  end)

  it("filters out directories that start with a dot (AC-1, AC-2)", function()
    local root = {
      id = 1,
      type = "directory",
      name = "workspace",
      path = "/workspace",
      expanded = true,
      childs = {
        {
          id = 2,
          type = "directory",
          name = ".git",
          path = "/workspace/.git",
          expanded = true,
          childs = {
            {
              id = 3,
              type = "file",
              name = "config",
              path = "/workspace/.git/config",
            },
          },
        },
        {
          id = 4,
          type = "directory",
          name = "src",
          path = "/workspace/src",
          expanded = false,
          childs = {
            {
              id = 5,
              type = "file",
              name = "index.lua",
              path = "/workspace/src/index.lua",
            },
          },
        },
      },
    }

    local items = ui.renderTree(root)
    assert.are.same({
      {
        line = " workspace",
        id = 1,
        extmarks = {
          { col_start = 0, col_end = 3, highlight = "SimpleTreeFolderIcon" },
          { col_start = 4, col_end = 13, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "   src",
        id = 4,
        extmarks = {
          { col_start = 2, col_end = 5, highlight = "SimpleTreeFolderIcon" },
          { col_start = 6, col_end = 9, highlight = "SimpleTreeDirectory" },
        },
      },
    }, items)
  end)

  it("filters out files starting with a dot and sorts folders before files (AC-2, AC-3, AC-4)", function()
    local root = {
      id = 1,
      type = "directory",
      name = "project",
      path = "/project",
      expanded = true,
      childs = {
        {
          id = 2,
          type = "file",
          name = ".gitignore",
          path = "/project/.gitignore",
        },
        {
          id = 3,
          type = "file",
          name = "main.lua",
          path = "/project/main.lua",
        },
        {
          id = 4,
          type = "directory",
          name = "docs",
          path = "/project/docs",
          expanded = true,
          childs = {
            {
              id = 5,
              type = "file",
              name = "README.md",
              path = "/project/docs/README.md",
            },
          },
        },
      },
    }

    local items = ui.renderTree(root)
    assert.are.same({
      {
        line = " project",
        id = 1,
        extmarks = {
          { col_start = 0, col_end = 3, highlight = "SimpleTreeFolderIcon" },
          { col_start = 4, col_end = 11, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "   docs",
        id = 4,
        extmarks = {
          { col_start = 2, col_end = 5, highlight = "SimpleTreeFolderIcon" },
          { col_start = 6, col_end = 10, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "    README.md",
        id = 5,
        extmarks = {
          { col_start = 4, col_end = 13, highlight = "SimpleTreeFile" },
        },
      },
      {
        line = "  main.lua",
        id = 3,
        extmarks = {
          { col_start = 2, col_end = 10, highlight = "SimpleTreeFile" },
        },
      },
    }, items)
  end)

  it("sorts folders before files and sorts alphabetically within groups (AC-4)", function()
    local root = {
      id = 1,
      type = "directory",
      name = "workspace",
      path = "/workspace",
      expanded = true,
      childs = {
        { id = 2, type = "file", name = "main.lua", path = "/workspace/main.lua" },
        { id = 3, type = "directory", name = "src", path = "/workspace/src", expanded = false },
        { id = 4, type = "file", name = "README.md", path = "/workspace/README.md" },
        { id = 5, type = "directory", name = "assets", path = "/workspace/assets", expanded = false },
        { id = 6, type = "file", name = "config.lua", path = "/workspace/config.lua" },
        { id = 7, type = "directory", name = "bin", path = "/workspace/bin", expanded = false },
      },
    }

    local items = ui.renderTree(root)
    assert.are.same({
      {
        line = " workspace",
        id = 1,
        extmarks = {
          { col_start = 0, col_end = 3, highlight = "SimpleTreeFolderIcon" },
          { col_start = 4, col_end = 13, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "   assets",
        id = 5,
        extmarks = {
          { col_start = 2, col_end = 5, highlight = "SimpleTreeFolderIcon" },
          { col_start = 6, col_end = 12, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "   bin",
        id = 7,
        extmarks = {
          { col_start = 2, col_end = 5, highlight = "SimpleTreeFolderIcon" },
          { col_start = 6, col_end = 9, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "   src",
        id = 3,
        extmarks = {
          { col_start = 2, col_end = 5, highlight = "SimpleTreeFolderIcon" },
          { col_start = 6, col_end = 9, highlight = "SimpleTreeDirectory" },
        },
      },
      {
        line = "  config.lua",
        id = 6,
        extmarks = {
          { col_start = 2, col_end = 12, highlight = "SimpleTreeFile" },
        },
      },
      {
        line = "  main.lua",
        id = 2,
        extmarks = {
          { col_start = 2, col_end = 10, highlight = "SimpleTreeFile" },
        },
      },
      {
        line = "  README.md",
        id = 4,
        extmarks = {
          { col_start = 2, col_end = 11, highlight = "SimpleTreeFile" },
        },
      },
    }, items)
  end)

  it("handles nodes without id by setting id to nil", function()
    local root = {
      type = "directory",
      name = "root",
      path = "/root",
      expanded = false,
    }

    local items = ui.renderTree(root)
    assert.are.same({
      {
        line = " root",
        id = nil,
        extmarks = {
          { col_start = 0, col_end = 3, highlight = "SimpleTreeFolderIcon" },
          { col_start = 4, col_end = 8, highlight = "SimpleTreeDirectory" },
        },
      },
    }, items)
  end)
end)
