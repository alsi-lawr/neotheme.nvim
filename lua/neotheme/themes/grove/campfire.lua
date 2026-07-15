local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#060d08",
	surface_dark = "#0a160e",
	surface_base = "#102018",
	surface_raised = "#172b20",
	surface_selected = "#28422f",
	surface_border = "#425b43",
	surface_muted = "#647461",
	surface_addition = "#1f4328",
	surface_error = "#5a2528",
	text_primary = "#d5c6a4",
	text_bright = "#eadab6",
	text_strong = "#fff0c9",
	text_muted = "#9c987c",
	text_on_accent = "#071008",
	text_on_error = "#fae3c5",
	syntax_comment = "#7f8f73",
	syntax_string = "#adca78",
	syntax_keyword = "#78aa5e",
	syntax_function_name = "#dfb65c",
	syntax_type = "#b394d0",
	syntax_property = "#df7fa8",
	syntax_literal = "#f0909e",
	diagnostic_error = "#e55b43",
	version_control_conflict = "#d45f71",
}

return transform(simplified)
