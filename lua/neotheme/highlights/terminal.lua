local M = {}

---@param p NeothemePalette
function M.apply(p)
	local paths = {
		{ "surface", "base" },
		{ "version_control", "conflict" },
		{ "diagnostic", "success" },
		{ "diagnostic", "warning" },
		{ "syntax", "property" },
		{ "diagnostic", "hint" },
		{ "text", "muted" },
		{ "text", "primary" },
		{ "surface", "base" },
		{ "diagnostic", "error" },
		{ "diagnostic", "success" },
		{ "diagnostic", "warning" },
		{ "diagnostic", "information" },
		{ "diagnostic", "hint" },
		{ "text", "muted" },
		{ "text", "on_error" },
	}

	for index, path in ipairs(paths) do
		vim.g["terminal_color_" .. (index - 1)] = p[path[1]][path[2]]
	end

	vim.g.terminal_color_background = p.surface.base
	vim.g.terminal_color_foreground = p.text.primary
end

return M
