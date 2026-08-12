local util = require("simple-tree.util")

describe("util.deepCopy", function()
	it("returns nil when node is nil", function()
		local result = util.deepCopy(nil)
		assert.is_nil(result)
	end)

	it("copies a leaf node without children", function()
		local node = {
			type = "file",
			name = "index.lua",
			path = "/root/index.lua",
		}

		local copy = util.deepCopy(node)

		assert.are_not.equal(node, copy)
		assert.are.same(node, copy)
		assert.is_nil(copy.childs)
	end)

	it("copies a node with an empty children array", function()
		local node = {
			type = "directory",
			name = "empty_folder",
			path = "/root/empty_folder",
			childs = {},
		}

		local copy = util.deepCopy(node)

		assert.are_not.equal(node, copy)
		assert.are_not.equal(node.childs, copy.childs)
		assert.are.same(node, copy)
		assert.equals(0, #copy.childs)
	end)

	it("recursively deep copies a nested tree structure", function()
		local tree = {
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
				{
					type = "file",
					name = "README.md",
					path = "/root/README.md",
				},
			},
		}

		local copy = util.deepCopy(tree)

		assert.are_not.equal(tree, copy)
		assert.are.same(tree, copy)

		-- Verify separate references for first-level children
		assert.are_not.equal(tree.childs, copy.childs)
		assert.are_not.equal(tree.childs[1], copy.childs[1])
		assert.are_not.equal(tree.childs[2], copy.childs[2])

		-- Verify separate references for second-level children
		assert.are_not.equal(tree.childs[1].childs, copy.childs[1].childs)
		assert.are_not.equal(tree.childs[1].childs[1], copy.childs[1].childs[1])
	end)

	it("ensures mutations on the copied tree do not affect the original tree", function()
		local tree = {
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

		local copy = util.deepCopy(tree)

		-- Mutate copy's top level property
		copy.name = "renamed_root"
		assert.equals("root", tree.name)
		assert.equals("renamed_root", copy.name)

		-- Mutate copy's nested child property
		copy.childs[1].childs[1].name = "modified.lua"
		assert.equals("main.lua", tree.childs[1].childs[1].name)
		assert.equals("modified.lua", copy.childs[1].childs[1].name)

		-- Insert new child into copy's nested directory
		table.insert(copy.childs[1].childs, {
			type = "file",
			name = "util.lua",
			path = "/root/src/util.lua",
		})
		assert.equals(1, #tree.childs[1].childs)
		assert.equals(2, #copy.childs[1].childs)
	end)

	it("preserves custom and extra properties recursively", function()
		local node = {
			type = "directory",
			name = "lib",
			path = "/root/lib",
			expanded = true,
			meta = {
				item_count = 5,
			},
			childs = {
				{
					type = "file",
					name = "core.lua",
					path = "/root/lib/core.lua",
					hidden = false,
				},
			},
		}

		local copy = util.deepCopy(node)

		assert.are.same(node, copy)
		assert.is_true(copy.expanded)
		assert.are_not.equal(node.meta, copy.meta)
		assert.equals(5, copy.meta.item_count)
		assert.is_false(copy.childs[1].hidden)

		-- Mutate nested meta object
		copy.meta.item_count = 10
		assert.equals(5, node.meta.item_count)
		assert.equals(10, copy.meta.item_count)
	end)
end)
