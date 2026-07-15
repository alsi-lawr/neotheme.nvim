local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#b7d8d8",
	surface_dark = "#c9e3e1",
	surface_base = "#e4f1ed",
	surface_raised = "#f4f5e9",
	surface_selected = "#c2e4e0",
	surface_border = "#8fbdbb",
	surface_muted = "#729e9c",
	surface_addition = "#d2e8d5",
	surface_error = "#f4d1c6",
	text_primary = "#173f49",
	text_bright = "#0d303a",
	text_strong = "#08242d",
	text_muted = "#57787a",
	text_on_accent = "#f4f5e9",
	text_on_error = "#55261f",
	syntax_comment = "#608583",
	syntax_string = "#0f777b",
	syntax_keyword = "#315fa5",
	syntax_function_name = "#9f4a58",
	syntax_type = "#477c72",
	syntax_property = "#396d86",
	syntax_literal = "#716292",
	diagnostic_error = "#b33240",
	version_control_conflict = "#825e45",
}

return transform(simplified)
