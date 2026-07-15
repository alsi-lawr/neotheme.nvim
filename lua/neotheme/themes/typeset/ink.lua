local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#111416",
	surface_dark = "#181c1e",
	surface_base = "#222729",
	surface_raised = "#2b3031",
	surface_selected = "#363b3b",
	surface_border = "#494e4c",
	surface_muted = "#686a63",
	surface_addition = "#2d3531",
	surface_error = "#493130",
	text_primary = "#d8cfbd",
	text_bright = "#e5dcc9",
	text_strong = "#f0e7d4",
	text_muted = "#a29b8d",
	text_on_accent = "#15191b",
	text_on_error = "#e8ddca",
	syntax_comment = "#958b7c",
	syntax_string = "#aaa38f",
	syntax_keyword = "#9ca8aa",
	syntax_function_name = "#a39daa",
	syntax_type = "#a099a4",
	syntax_property = "#96a5a0",
	syntax_literal = "#ab9d8b",
	diagnostic_error = "#c77a72",
	version_control_conflict = "#ca846f",
}

return transform(simplified)
