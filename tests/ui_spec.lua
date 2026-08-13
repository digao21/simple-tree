local ui = require("simple-tree.ui")

describe("ui.renderTree", function()
	it("returns empty list when root is nil", function()
		local lines = ui.renderTree(nil)
		assert.are.same({}, lines)
	end)

	it("renders a single root node with no children", function()
		local root = {
			type = "directory",
			name = "my_project",
			path = "/path/to/my_project",
		}

		local lines = ui.renderTree(root)
		assert.are.same({ "my_project" }, lines)
	end)

	it("renders a root node with children using 2-space indentation", function()
		local root = {
			type = "directory",
			name = "my_project",
			path = "/path/to/my_project",
			childs = {
				{
					type = "file",
					name = "init.lua",
					path = "/path/to/my_project/init.lua",
				},
				{
					type = "file",
					name = "README.md",
					path = "/path/to/my_project/README.md",
				},
			},
		}

		local lines = ui.renderTree(root)
		assert.are.same({
			"my_project",
			"  init.lua",
			"  README.md",
		}, lines)
	end)

	it("renders deeply nested hierarchies with proper level indentation", function()
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
							type = "directory",
							name = "core",
							path = "/root/src/core",
							childs = {
								{
									type = "file",
									name = "engine.lua",
									path = "/root/src/core/engine.lua",
								},
							},
						},
						{
							type = "file",
							name = "main.lua",
							path = "/root/src/main.lua",
						},
					},
				},
				{
					type = "file",
					name = "package.json",
					path = "/root/package.json",
				},
			},
		}

		local lines = ui.renderTree(root)
		assert.are.same({
			"root",
			"  src",
			"    core",
			"      engine.lua",
			"    main.lua",
			"  package.json",
		}, lines)
	end)
end)
