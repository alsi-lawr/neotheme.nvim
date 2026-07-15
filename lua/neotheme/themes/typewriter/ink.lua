local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#b8b5ae",
	surface_dark = "#ddd9d1",
	surface_base = "#f6f2e9",
	surface_raised = "#fffdf8",
	surface_selected = "#cac7c0",
	surface_border = "#9b9892",
	surface_muted = "#77736e",
	surface_addition = "#dce3dd",
	surface_error = "#ecd8d6",
	text_primary = "#20201f",
	text_bright = "#131414",
	text_strong = "#050606",
	text_muted = "#5f5c57",
	text_on_accent = "#ffffff",
	text_on_error = "#481619",
	syntax_comment = "#6b6863",
	syntax_string = "#514841",
	syntax_keyword = "#171a1c",
	syntax_function_name = "#30373b",
	syntax_type = "#5f574f",
	syntax_property = "#3e3b39",
	syntax_literal = "#4d575c",
	diagnostic_error = "#a23238",
	version_control_conflict = "#7d3f55",
}

return transform(simplified)
