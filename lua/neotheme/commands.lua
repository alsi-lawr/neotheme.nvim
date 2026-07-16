local M = {}

local function create_user_command(name, callback, options)
	if vim.fn.exists(":" .. name) == 2 then
		return
	end

	vim.api.nvim_create_user_command(name, callback, options)
end

local function filtered_families(prefix)
	local matches = {}
	for _, family in ipairs(require("neotheme").families()) do
		if vim.startswith(family, prefix) then
			table.insert(matches, family)
		end
	end
	return matches
end

local function list_themes(family)
	local neotheme = require("neotheme")
	local lines = {}

	if family then
		lines = neotheme.themes(family)
	else
		for _, name in ipairs(neotheme.families()) do
			table.insert(lines, name)
			for _, theme in ipairs(neotheme.themes(name)) do
				table.insert(lines, "  " .. theme)
			end
		end
	end

	vim.api.nvim_echo({ { table.concat(lines, "\n") } }, true, {})
end

function M.register()
	create_user_command("NeothemeList", function(arguments)
		if arguments.args:find("%s") then
			error("neotheme: NeothemeList accepts at most one family argument")
		end

		local family = arguments.args ~= "" and arguments.args or nil
		list_themes(family)
	end, {
		nargs = "?",
		complete = function(argument_lead)
			return filtered_families(argument_lead)
		end,
		desc = "List Neotheme families or the themes in one family",
	})
end

return M
