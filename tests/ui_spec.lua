local ui = require("simple-tree.ui")

describe("ui.renderTree", function()
	it("exposes folder icon constants and aliases", function()
		assert.equals("", ui.FOLDER_ICON_CLOSED)
		assert.equals("", ui.FOLDER_ICON_CLOSE)
		assert.equals("", ui.FOLDER_ICON_OPEN)
	end)

	it("returns empty list and empty map when root is nil", function()
		local lines, line_to_id = ui.renderTree(nil)
		assert.are.same({}, lines)
		assert.are.same({}, line_to_id)
	end)

	it("renders a single root node with default closed folder icon and line_to_id map", function()
		local root = {
			id = 1,
			type = "directory",
			name = "my_project",
			path = "/path/to/my_project",
			expanded = false,
		}

		local lines, line_to_id = ui.renderTree(root)
		assert.are.same({ " my_project" }, lines)
		assert.are.same({ [1] = 1 }, line_to_id)
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

		local lines, line_to_id = ui.renderTree(root)
		assert.are.same({
			" my_project",
			"  init.lua",
		}, lines)
		assert.are.same({ [1] = 1, [2] = 2 }, line_to_id)
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

		local lines, line_to_id = ui.renderTree(root)
		assert.are.same({ " my_project" }, lines)
		assert.are.same({ [1] = 1 }, line_to_id)
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

		local lines, line_to_id = ui.renderTree(root)
		assert.are.same({
			" root",
			"   src",
			"     core",
			"    main.lua",
			"  package.json",
		}, lines)
		assert.are.same({
			[1] = 1,
			[2] = 2,
			[3] = 3,
			[4] = 5,
			[5] = 6,
		}, line_to_id)
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

		local lines, line_to_id = ui.renderTree(root)
		assert.are.same({
			" workspace",
			"   src",
		}, lines)
		assert.are.same({ [1] = 1, [2] = 4 }, line_to_id)
	end)

	it("filters out files starting with a dot (AC-2, AC-3)", function()
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

		local lines, line_to_id = ui.renderTree(root)
		assert.are.same({
			" project",
			"  main.lua",
			"   docs",
			"    README.md",
		}, lines)
		assert.are.same({
			[1] = 1,
			[2] = 3,
			[3] = 4,
			[4] = 5,
		}, line_to_id)
	end)
end)
