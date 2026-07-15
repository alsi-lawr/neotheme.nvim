local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#b3bab9",
	surface_dark = "#cbd0cf",
	surface_base = "#e2e4e0",
	surface_raised = "#f0f1ed",
	surface_selected = "#cbd1ce",
	surface_border = "#a9b1b1",
	surface_muted = "#7b8587",
	surface_addition = "#c6d7d1",
	surface_error = "#dcb9ad",
	text_primary = "#343a3b",
	text_bright = "#252b2d",
	text_strong = "#171b1c",
	text_muted = "#5d6769",
	text_on_accent = "#f9efea",
	text_on_error = "#481d18",
	syntax_comment = "#795746",
	syntax_string = "#3f6c77",
	syntax_keyword = "#a94732",
	syntax_function_name = "#456a83",
	syntax_type = "#3a6b62",
	syntax_property = "#56666a",
	syntax_literal = "#855b48",
	diagnostic_error = "#a83228",
	version_control_conflict = "#b54a32",
}

return transform(simplified)
