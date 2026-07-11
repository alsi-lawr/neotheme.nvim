local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#d8cdbd",
	surface_dark = "#e4d8c8",
	surface_base = "#f2e8db",
	surface_raised = "#faf3e9",
	surface_selected = "#e5d8c1",
	surface_border = "#c7b8a4",
	surface_muted = "#ac9c87",
	surface_addition = "#dce9d8",
	surface_error = "#e6b3ab",
	text_primary = "#3f352b",
	text_bright = "#2c251e",
	text_strong = "#1f1a15",
	text_on_accent = "#221a13",
	text_on_error = "#431a17",
	syntax_comment = "#8c6d4f",
	syntax_string = "#4f7f48",
	syntax_keyword = "#8e641b",
	syntax_function_name = "#3e638f",
	syntax_type = "#4b7066",
	syntax_property = "#687486",
	syntax_literal = "#705f9a",
	diagnostic_error = "#ae3e3b",
	version_control_conflict = "#bd514c",
}

return transform(simplified)
