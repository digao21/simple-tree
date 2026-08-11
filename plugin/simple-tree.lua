local cmd = require("simple-tree.command")

vim.api.nvim_create_user_command("SimpleTree", function(opts)
	local args = opts.args
	if args == "print" then
		cmd.printFilesystem()
	end
end, {
	nargs = 1,
	complete = function(arg)
		local matchs = {}
		local subcmds = { "print" }

		for _, subcmd in ipairs(subcmds) do
			if subcmd:sub(1, #arg) == arg then
				table.insert(matchs, subcmd)
			end
		end

		return matchs
	end,
})
