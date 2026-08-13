local fs_store = require("simple-tree.filesystem")

describe("filesystem state store", function()
	it("stores and retrieves root node as a deep copy", function()
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
		local retrieved = fs_store.getRoot()

		assert.are_not.equal(initial_root, retrieved)
		assert.are.same(initial_root, retrieved)

		-- Mutating retrieved does not affect stored state
		retrieved.name = "mutated_project"
		local retrieved2 = fs_store.getRoot()
		assert.equals("project", retrieved2.name)
	end)
end)
