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

local function filtered_themes(prefix)
	local matches = {}
	for _, theme in ipairs(require("neotheme").themes()) do
		if theme ~= "custom" and vim.startswith(theme, prefix) then
			table.insert(matches, theme)
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

local function show_current()
	local current = require("neotheme").current()
	local lines = {
		current.active_theme and "active: " .. current.active_theme or "active: not loaded",
	}

	if current.family then
		table.insert(lines, "family: " .. current.family)
	end
	table.insert(lines, "configured: " .. current.configured_theme)
	if current.background then
		table.insert(lines, "background: " .. current.background)
	end
	table.insert(lines, "session override: " .. (current.session_override and "yes" or "no"))

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

	create_user_command("NeothemeSwitch", function(arguments)
		if arguments.args == "" then
			error("neotheme: NeothemeSwitch requires a theme argument")
		end
		if arguments.args:find("%s") then
			error("neotheme: NeothemeSwitch accepts exactly one theme argument")
		end

		require("neotheme").switch(arguments.args)
	end, {
		nargs = "?",
		complete = function(argument_lead)
			return filtered_themes(argument_lead)
		end,
		desc = "Switch Neotheme for the current session",
	})

	create_user_command("NeothemeCurrent", function(arguments)
		if arguments.args ~= "" then
			error("neotheme: NeothemeCurrent accepts no arguments")
		end

		show_current()
	end, {
		nargs = "*",
		desc = "Show the current Neotheme session state",
	})

	create_user_command("NeothemeReset", function(arguments)
		if arguments.args ~= "" then
			error("neotheme: NeothemeReset accepts no arguments")
		end

		require("neotheme").reset()
	end, {
		nargs = "*",
		desc = "Reset Neotheme to the configured baseline",
	})

	create_user_command("NeothemeReload", function(arguments)
		if arguments.args ~= "" then
			error("neotheme: NeothemeReload accepts no arguments")
		end

		require("neotheme").reload()
	end, {
		nargs = "*",
		desc = "Reload the active Neotheme selection",
	})
end

return M
