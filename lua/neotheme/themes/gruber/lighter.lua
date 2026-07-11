local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#e5ddd1",
	surface_dark = "#eee7dc",
	surface_base = "#faf5ed",
	surface_raised = "#fffdf8",
	surface_selected = "#e9dbc6",
	surface_border = "#cfc2b0",
	surface_muted = "#b4a694",
	surface_addition = "#e3efe0",
	surface_error = "#ecc0b8",
	text_primary = "#342b23",
	text_bright = "#211b16",
	text_strong = "#15110e",
	text_on_accent = "#1d1711",
	text_on_error = "#371412",
	syntax_comment = "#8b6745",
	syntax_string = "#397a3f",
	syntax_keyword = "#875600",
	syntax_function_name = "#285f94",
	syntax_type = "#356c5d",
	syntax_property = "#596d86",
	syntax_literal = "#654e98",
	diagnostic_error = "#aa292f",
	version_control_conflict = "#c13e43",
}

return transform(simplified)
