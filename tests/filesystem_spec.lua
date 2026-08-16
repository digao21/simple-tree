local fs_store = require("simple-tree.filesystem")

describe("filesystem state store", function()
  it("stores and retrieves root node as a deep copy with assigned IDs", function()
    local initial_root = {
      type = "directory",
      name = "project",
      path = "/workspace/project",
      childs = {
        {
          type = "file",
          name = "init.lua",
          path = "/workspace/project/init.lua",
        },
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

    fs_store.setRoot(initial_root)
    local retrieved = fs_store.getRoot()

    assert.are_not.equal(initial_root, retrieved)
    assert.equals(1, retrieved.id)
    assert.is_true(retrieved.expanded)
    assert.equals(2, retrieved.childs[1].id)
    assert.equals(3, retrieved.childs[2].id)
    assert.equals(4, retrieved.childs[2].childs[1].id)

    -- Mutating retrieved does not affect stored state
    retrieved.name = "mutated_project"
    local retrieved2 = fs_store.getRoot()
    assert.equals("project", retrieved2.name)
  end)

  it("retrieves node by ID via getNodeById", function()
    local initial_root = {
      type = "directory",
      name = "project",
      path = "/workspace/project",
      childs = {
        {
          type = "file",
          name = "init.lua",
          path = "/workspace/project/init.lua",
        },
      },
    }

    fs_store.setRoot(initial_root)
    local node1 = fs_store.getNodeById(1)
    local node2 = fs_store.getNodeById(2)
    local node99 = fs_store.getNodeById(99)

    assert.equals("project", node1.name)
    assert.equals("init.lua", node2.name)
    assert.is_nil(node99)
  end)

  it("toggles directory expansion state via toggleFolder", function()
    local initial_root = {
      type = "directory",
      name = "project",
      path = "/workspace/project",
      childs = {
        {
          type = "directory",
          name = "src",
          path = "/workspace/project/src",
          childs = {},
        },
        {
          type = "file",
          name = "init.lua",
          path = "/workspace/project/init.lua",
        },
      },
    }

    fs_store.setRoot(initial_root)
    local src_node = fs_store.getNodeById(2)
    assert.is_nil(src_node.expanded)

    -- Toggle directory (ID 2)
    local toggled = fs_store.toggleFolder(2)
    assert.is_true(toggled)
    local updated_src = fs_store.getNodeById(2)
    assert.is_true(updated_src.expanded)

    -- Toggle directory back to collapsed
    toggled = fs_store.toggleFolder(2)
    assert.is_true(toggled)
    updated_src = fs_store.getNodeById(2)
    assert.is_false(updated_src.expanded)

    -- Toggle file (ID 3) should no-op
    local file_toggled = fs_store.toggleFolder(3)
    assert.is_false(file_toggled)
  end)
end)
