local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#07151d",
	surface_dark = "#0b202a",
	surface_base = "#102a35",
	surface_raised = "#173743",
	surface_selected = "#204b58",
	surface_border = "#2a5964",
	surface_muted = "#52747a",
	surface_addition = "#173d38",
	surface_error = "#633d43",
	text_primary = "#c7ddd9",
	text_bright = "#e5f3ec",
	text_strong = "#f4eedb",
	text_muted = "#7fa09e",
	text_on_accent = "#06171d",
	text_on_error = "#fff2e3",
	syntax_comment = "#6d9694",
	syntax_string = "#62b8ad",
	syntax_keyword = "#6f8fe5",
	syntax_function_name = "#f2a08c",
	syntax_type = "#a9c9a2",
	syntax_property = "#7fa9c4",
	syntax_literal = "#b1a6cf",
	diagnostic_error = "#e76870",
	version_control_conflict = "#c78465",
}

return transform(simplified)
