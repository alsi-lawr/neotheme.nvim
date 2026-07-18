local templates = {
	dark = {
		surface_deepest = "#000000",
		surface_dark = "#121212",
		surface_base = "#1c1c1c",
		surface_raised = "#262626",
		surface_selected = "#3a3a3a",
		surface_border = "#585858",
		surface_muted = "#767676",
		surface_addition = "#1f3d2b",
		surface_error = "#d78787",
		text_primary = "#d0d0d0",
		text_bright = "#eeeeee",
		text_strong = "#ffffff",
		text_muted = "#9e9e9e",
		text_on_accent = "#000000",
		text_on_error = "#000000",
		syntax_comment = "#808080",
		syntax_string = "#87af87",
		syntax_keyword = "#af87af",
		syntax_function_name = "#87afd7",
		syntax_type = "#87afaf",
		syntax_property = "#d7af87",
		syntax_literal = "#d7af87",
		diagnostic_error = "#d78787",
		version_control_conflict = "#d78787",
	},
	light = {
		surface_deepest = "#d7d7d7",
		surface_dark = "#e4e4e4",
		surface_base = "#f5f5f5",
		surface_raised = "#ffffff",
		surface_selected = "#d7e3f0",
		surface_border = "#a8a8a8",
		surface_muted = "#c6c6c6",
		surface_addition = "#dcebdc",
		surface_error = "#8b3030",
		text_primary = "#303030",
		text_bright = "#1c1c1c",
		text_strong = "#000000",
		text_muted = "#686868",
		text_on_accent = "#ffffff",
		text_on_error = "#ffffff",
		syntax_comment = "#707070",
		syntax_string = "#4f7f4f",
		syntax_keyword = "#7a3e7a",
		syntax_function_name = "#2f5f8f",
		syntax_type = "#3f6f6f",
		syntax_property = "#805f3f",
		syntax_literal = "#8a5a2b",
		diagnostic_error = "#b03030",
		version_control_conflict = "#9a4040",
	},
}

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

local M = {}

---@param background "dark"|"light"
---@return NeothemeSimplifiedPalette
function M.get(background)
	local template = templates[background]
	if template == nil then
		error("neotheme: neutral simplified palette background must be dark or light", 2)
	end
	return copy(template)
end

return M
