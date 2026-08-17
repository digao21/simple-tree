local fs_store = require("simple-tree.model")

describe("filesystem domain model", function()
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

  describe("observer pattern", function()
    before_each(function() fs_store.clearSubscribers() end)

    after_each(function() fs_store.clearSubscribers() end)

    it("notifies subscribers when setRoot is called", function()
      local notifications = {}
      local unsubscribe = fs_store.subscribe(function(root) table.insert(notifications, root) end)

      local root_data = {
        type = "directory",
        name = "workspace",
        path = "/workspace",
      }

      fs_store.setRoot(root_data)

      assert.equals(1, #notifications)
      assert.equals("workspace", notifications[1].name)
      assert.equals(1, notifications[1].id)

      unsubscribe()
      fs_store.setRoot({ type = "directory", name = "workspace2", path = "/workspace2" })
      assert.equals(1, #notifications)
    end)

    it("notifies subscribers when toggleFolder mutates a directory node", function()
      local root_data = {
        type = "directory",
        name = "project",
        path = "/project",
        childs = {
          {
            type = "directory",
            name = "src",
            path = "/project/src",
          },
          {
            type = "file",
            name = "main.lua",
            path = "/project/main.lua",
          },
        },
      }

      fs_store.setRoot(root_data)

      local notifications = {}
      fs_store.subscribe(function(root) table.insert(notifications, root) end)

      -- Toggle directory (ID 2) -> should notify
      local toggled = fs_store.toggleFolder(2)
      assert.is_true(toggled)
      assert.equals(1, #notifications)
      assert.is_true(notifications[1].childs[1].expanded)

      -- Toggle file (ID 3) -> should NOT notify
      local file_toggled = fs_store.toggleFolder(3)
      assert.is_false(file_toggled)
      assert.equals(1, #notifications)

      -- Toggle invalid ID (ID 999) -> should NOT notify
      local invalid_toggled = fs_store.toggleFolder(999)
      assert.is_false(invalid_toggled)
      assert.equals(1, #notifications)
    end)

    it("supports unsubscribe via fs_store.unsubscribe", function()
      local call_count = 0
      local sub = function() call_count = call_count + 1 end

      fs_store.addSubscriber(sub)
      fs_store.setRoot({ type = "directory", name = "root", path = "/root" })
      assert.equals(1, call_count)

      fs_store.unsubscribe(sub)
      fs_store.setRoot({ type = "directory", name = "root2", path = "/root2" })
      assert.equals(1, call_count)
    end)

    it("notifies multiple subscribers independently", function()
      local sub1_calls = 0
      local sub2_calls = 0

      fs_store.subscribe(function() sub1_calls = sub1_calls + 1 end)
      fs_store.subscribe(function() sub2_calls = sub2_calls + 1 end)

      fs_store.setRoot({ type = "directory", name = "root", path = "/root" })
      assert.equals(1, sub1_calls)
      assert.equals(1, sub2_calls)
    end)
  end)
end)
