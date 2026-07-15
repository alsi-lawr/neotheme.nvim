local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#cbd3ce",
	surface_dark = "#d7dfda",
	surface_base = "#e4e9e5",
	surface_raised = "#eef1ed",
	surface_selected = "#d3ddd7",
	surface_border = "#b4c1ba",
	surface_muted = "#899a92",
	surface_addition = "#d3e1d7",
	surface_error = "#dfc7c3",
	text_primary = "#3d5148",
	text_bright = "#2e433a",
	text_strong = "#20352c",
	text_muted = "#596b62",
	text_on_accent = "#f5f8f5",
	text_on_error = "#452b28",
	syntax_comment = "#71645b",
	syntax_string = "#586a4d",
	syntax_keyword = "#566c59",
	syntax_function_name = "#4e6f61",
	syntax_type = "#666844",
	syntax_property = "#6b625a",
	syntax_literal = "#78603f",
	diagnostic_error = "#94534f",
	version_control_conflict = "#9c6051",
}

return transform(simplified)
