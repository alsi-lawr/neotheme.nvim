local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#9fa274",
	surface_dark = "#c2bd8f",
	surface_base = "#e3d3a7",
	surface_raised = "#f0e2bc",
	surface_selected = "#bec795",
	surface_border = "#7f8b60",
	surface_muted = "#817b5f",
	surface_addition = "#c4d4a4",
	surface_error = "#d9a29a",
	text_primary = "#352e23",
	text_bright = "#262019",
	text_strong = "#191510",
	text_muted = "#655b43",
	text_on_accent = "#f5e8c4",
	text_on_error = "#4f171a",
	syntax_comment = "#625943",
	syntax_string = "#445f32",
	syntax_keyword = "#315d3a",
	syntax_function_name = "#735719",
	syntax_type = "#624a80",
	syntax_property = "#94335f",
	syntax_literal = "#983647",
	diagnostic_error = "#9d3029",
	version_control_conflict = "#73303d",
}

return transform(simplified)
