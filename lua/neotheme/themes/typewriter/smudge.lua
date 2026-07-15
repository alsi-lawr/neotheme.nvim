local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#aaa69f",
	surface_dark = "#c6c2bb",
	surface_base = "#dedbd4",
	surface_raised = "#ebe8e1",
	surface_selected = "#bbb8b2",
	surface_border = "#9c9993",
	surface_muted = "#85817b",
	surface_addition = "#c9d1ca",
	surface_error = "#d8c2c0",
	text_primary = "#504e4a",
	text_bright = "#383735",
	text_strong = "#222221",
	text_muted = "#706c66",
	text_on_accent = "#f4f1ea",
	text_on_error = "#4b2424",
	syntax_comment = "#7d7973",
	syntax_string = "#685e56",
	syntax_keyword = "#42484b",
	syntax_function_name = "#535e64",
	syntax_type = "#726b64",
	syntax_property = "#595653",
	syntax_literal = "#677074",
	diagnostic_error = "#9f4e50",
	version_control_conflict = "#825361",
}

return transform(simplified)
