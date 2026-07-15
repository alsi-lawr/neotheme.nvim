local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#000000",
	surface_dark = "#050606",
	surface_base = "#090a0b",
	surface_raised = "#111315",
	surface_selected = "#24272a",
	surface_border = "#3c3f42",
	surface_muted = "#64676a",
	surface_addition = "#18271f",
	surface_error = "#3d2022",
	text_primary = "#e3e1dc",
	text_bright = "#f4f2ed",
	text_strong = "#ffffff",
	text_muted = "#aaa7a1",
	text_on_accent = "#08090a",
	text_on_error = "#fff5f2",
	syntax_comment = "#898783",
	syntax_string = "#c5bfb6",
	syntax_keyword = "#f2f4f5",
	syntax_function_name = "#d5dadd",
	syntax_type = "#9e9992",
	syntax_property = "#b7b9ba",
	syntax_literal = "#a3afb4",
	diagnostic_error = "#ef7d7d",
	version_control_conflict = "#cf7696",
}

return transform(simplified)
