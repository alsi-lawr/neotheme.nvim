local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#bcb8b1",
	surface_dark = "#d2cfc8",
	surface_base = "#e4e1da",
	surface_raised = "#ebe8e1",
	surface_selected = "#cbc8c1",
	surface_border = "#aaa69f",
	surface_muted = "#96918a",
	surface_addition = "#d2d9d3",
	surface_error = "#ddcdcb",
	text_primary = "#66635e",
	text_bright = "#5c5a56",
	text_strong = "#4f4d49",
	text_muted = "#85817a",
	text_on_accent = "#f3f0e9",
	text_on_error = "#603536",
	syntax_comment = "#83807a",
	syntax_string = "#796a61",
	syntax_keyword = "#5c6265",
	syntax_function_name = "#687176",
	syntax_type = "#837970",
	syntax_property = "#6c6965",
	syntax_literal = "#777f83",
	diagnostic_error = "#965457",
	version_control_conflict = "#80606a",
}

return transform(simplified)
