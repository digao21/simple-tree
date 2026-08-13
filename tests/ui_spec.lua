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

	it("filters out directories that start with a dot (AC-1, AC-2)", function()
		local root = {
			type = "directory",
			name = "workspace",
			path = "/workspace",
			childs = {
				{
					type = "directory",
					name = ".git",
					path = "/workspace/.git",
					childs = {
						{
							type = "file",
							name = "config",
							path = "/workspace/.git/config",
						},
						{
							type = "directory",
							name = "objects",
							path = "/workspace/.git/objects",
							childs = {},
						},
					},
				},
				{
					type = "directory",
					name = ".cache",
					path = "/workspace/.cache",
					childs = {
						{
							type = "file",
							name = "cache.db",
							path = "/workspace/.cache/cache.db",
						},
					},
				},
				{
					type = "directory",
					name = "src",
					path = "/workspace/src",
					childs = {
						{
							type = "file",
							name = "index.lua",
							path = "/workspace/src/index.lua",
						},
					},
				},
			},
		}

		local lines = ui.renderTree(root)
		assert.are.same({
			"workspace",
			"  src",
			"    index.lua",
		}, lines)
	end)

	it("filters out files starting with a dot (AC-2, AC-3)", function()
		local root = {
			type = "directory",
			name = "project",
			path = "/project",
			childs = {
				{
					type = "directory",
					name = ".github",
					path = "/project/.github",
					childs = {
						{
							type = "file",
							name = "ci.yml",
							path = "/project/.github/ci.yml",
						},
					},
				},
				{
					type = "file",
					name = ".gitignore",
					path = "/project/.gitignore",
				},
				{
					type = "file",
					name = ".env",
					path = "/project/.env",
				},
				{
					type = "file",
					name = "main.lua",
					path = "/project/main.lua",
				},
				{
					type = "directory",
					name = "docs",
					path = "/project/docs",
					childs = {
						{
							type = "file",
							name = "README.md",
							path = "/project/docs/README.md",
						},
					},
				},
			},
		}

		local lines = ui.renderTree(root)
		assert.are.same({
			"project",
			"  main.lua",
			"  docs",
			"    README.md",
		}, lines)
	end)
end)
