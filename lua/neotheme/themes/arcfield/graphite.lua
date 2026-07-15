local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#020307",
	surface_dark = "#05070e",
	surface_base = "#080b13",
	surface_raised = "#101522",
	surface_selected = "#202634",
	surface_border = "#373d4b",
	surface_muted = "#587584",
	surface_addition = "#143936",
	surface_error = "#4d2d46",
	text_primary = "#c5d5dc",
	text_bright = "#e6f4f8",
	text_strong = "#f8fdff",
	text_muted = "#8199a4",
	text_on_accent = "#031016",
	text_on_error = "#fff5f8",
	syntax_comment = "#718996",
	syntax_string = "#65c7ad",
	syntax_keyword = "#3ddcff",
	syntax_function_name = "#a6d2ff",
	syntax_type = "#79a9c5",
	syntax_property = "#d7c78c",
	syntax_literal = "#f4d774",
	diagnostic_error = "#ef6c8f",
	version_control_conflict = "#ff4f87",
}

return transform(simplified)
