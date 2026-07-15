local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#d0d4cd",
	surface_dark = "#dfe1d8",
	surface_base = "#ecece2",
	surface_raised = "#f7f3e8",
	surface_selected = "#d9ddd2",
	surface_border = "#b8bdb3",
	surface_muted = "#929c96",
	surface_addition = "#dce5d8",
	surface_error = "#e8d2cc",
	text_primary = "#344b50",
	text_bright = "#243d43",
	text_strong = "#183138",
	text_muted = "#697a79",
	text_on_accent = "#f7f3e8",
	text_on_error = "#542e2c",
	syntax_comment = "#788682",
	syntax_string = "#4a716f",
	syntax_keyword = "#52668f",
	syntax_function_name = "#8b595f",
	syntax_type = "#738579",
	syntax_property = "#667e86",
	syntax_literal = "#6f657f",
	diagnostic_error = "#9d3f48",
	version_control_conflict = "#76604d",
}

return transform(simplified)
