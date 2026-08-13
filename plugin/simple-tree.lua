local cmd = require("simple-tree.command")

vim.api.nvim_create_user_command("SimpleTree", function(opts)
	local subcommand = opts.args
	if subcommand == "open" then
		cmd.open()
	elseif subcommand == "close" then
		cmd.close()
	elseif subcommand == "toggle" then
		cmd.toggle()
	end
end, {
	nargs = 1,
	complete = function(arg)
		local matches = {}
		local subcmds = { "open", "close", "toggle" }

		for _, subcmd in ipairs(subcmds) do
			if subcmd:sub(1, #arg) == arg then
				table.insert(matches, subcmd)
			end
		end

		return matches
	end,
})
