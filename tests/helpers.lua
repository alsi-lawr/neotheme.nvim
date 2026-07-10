local M = {}

local function message(label, expected, actual)
	return string.format(
		"%s\nexpected: %s\nactual:   %s",
		label or "values differ",
		vim.inspect(expected),
		vim.inspect(actual)
	)
end

function M.eq(expected, actual, label)
	if not vim.deep_equal(expected, actual) then
		error(message(label, expected, actual), 2)
	end
end

function M.truthy(value, label)
	if not value then
		error(label or "expected a truthy value", 2)
	end
end

function M.falsy(value, label)
	if value then
		error(label or "expected a falsy value", 2)
	end
end

function M.color(value)
	return tonumber(value:sub(2), 16)
end

function M.highlight(name, links)
	return vim.api.nvim_get_hl(0, { name = name, link = links == true })
end

function M.load(options)
	if options then
		require("neotheme").setup(options)
	end
	vim.cmd.colorscheme("neotheme")
end

function M.group_exists(name)
	return vim.fn.hlexists(name) == 1
end

return M
