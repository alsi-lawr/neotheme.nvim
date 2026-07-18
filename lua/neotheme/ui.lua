local M = {}

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in pairs(value) do
		result[key] = copy(item)
	end
	return result
end

function M.highlight(namespace, name)
	local definition = vim.api.nvim_get_hl(namespace, { name = name })
	if namespace ~= 0 and vim.tbl_isempty(definition) then
		return vim.api.nvim_get_hl(0, { name = name })
	end
	return definition
end

function M.apply_browser_chrome(namespace)
	namespace = namespace or 0
	local normal = M.highlight(namespace, "Normal")
	local title = M.highlight(namespace, "Title")
	local comment = M.highlight(namespace, "Comment")
	local title_definition = copy(title)
	title_definition.fg = title_definition.fg or normal.fg
	title_definition.bg = normal.bg
	vim.api.nvim_set_hl(namespace, "NeothemeBrowserFloat", normal)
	vim.api.nvim_set_hl(namespace, "NeothemeBrowserBorder", {
		fg = normal.fg,
		bg = normal.bg,
	})
	vim.api.nvim_set_hl(namespace, "NeothemeBrowserTitle", title_definition)
	vim.api.nvim_set_hl(namespace, "NeothemeBrowserTabActive", title)
	vim.api.nvim_set_hl(namespace, "NeothemeBrowserTabInactive", comment)
	if namespace ~= 0 then
		vim.api.nvim_set_hl(namespace, "FloatBorder", {
			fg = normal.fg,
			bg = normal.bg,
		})
	end
end

return M
