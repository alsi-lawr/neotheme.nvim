local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#08110d",
	surface_dark = "#0d1913",
	surface_base = "#122019",
	surface_raised = "#192a21",
	surface_selected = "#253a2e",
	surface_border = "#365044",
	surface_muted = "#587065",
	surface_addition = "#173424",
	surface_error = "#5a302e",
	text_primary = "#cbd8ca",
	text_bright = "#dce7d8",
	text_strong = "#eef4e9",
	text_muted = "#8fa398",
	text_on_accent = "#08130f",
	text_on_error = "#f7e9e2",
	syntax_comment = "#9b7f69",
	syntax_string = "#9fba72",
	syntax_keyword = "#78a681",
	syntax_function_name = "#6fb293",
	syntax_type = "#b8b278",
	syntax_property = "#a38f7d",
	syntax_literal = "#d1a35a",
	diagnostic_error = "#d8796e",
	version_control_conflict = "#de8a68",
}

return transform(simplified)
