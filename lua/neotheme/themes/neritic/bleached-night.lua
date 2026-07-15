local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#11191d",
	surface_dark = "#182327",
	surface_base = "#202d31",
	surface_raised = "#29383b",
	surface_selected = "#354548",
	surface_border = "#485a5b",
	surface_muted = "#667473",
	surface_addition = "#2d4039",
	surface_error = "#5a4040",
	text_primary = "#d2d0c7",
	text_bright = "#e5e0d4",
	text_strong = "#f0e8d9",
	text_muted = "#939c98",
	text_on_accent = "#161d1e",
	text_on_error = "#f4e9dd",
	syntax_comment = "#83918b",
	syntax_string = "#68a497",
	syntax_keyword = "#7295cc",
	syntax_function_name = "#b38e88",
	syntax_type = "#9fa995",
	syntax_property = "#78939d",
	syntax_literal = "#a6a0b6",
	diagnostic_error = "#d67676",
	version_control_conflict = "#9c9270",
}

return transform(simplified)
