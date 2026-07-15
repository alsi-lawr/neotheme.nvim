local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#0c0e0f",
	surface_dark = "#141719",
	surface_base = "#1d2123",
	surface_raised = "#272c2f",
	surface_selected = "#343b3e",
	surface_border = "#465055",
	surface_muted = "#657073",
	surface_addition = "#203730",
	surface_error = "#67352d",
	text_primary = "#d3d7d5",
	text_bright = "#e4e7e4",
	text_strong = "#f1f2ed",
	text_muted = "#899396",
	text_on_accent = "#15191a",
	text_on_error = "#fff3ee",
	syntax_comment = "#b27a60",
	syntax_string = "#88a7ae",
	syntax_keyword = "#cf6b4e",
	syntax_function_name = "#91a9bb",
	syntax_type = "#74a195",
	syntax_property = "#929fa3",
	syntax_literal = "#bd8469",
	diagnostic_error = "#df5f49",
	version_control_conflict = "#e67555",
}

return transform(simplified)
