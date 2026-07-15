local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#0f1514",
	surface_dark = "#151d1b",
	surface_base = "#1b2522",
	surface_raised = "#222e2a",
	surface_selected = "#2e3c37",
	surface_border = "#3c4e48",
	surface_muted = "#5b6d66",
	surface_addition = "#24362d",
	surface_error = "#533836",
	text_primary = "#c2cdc7",
	text_bright = "#d1dbd5",
	text_strong = "#e0e7e2",
	text_muted = "#8a9a93",
	text_on_accent = "#101816",
	text_on_error = "#ede2dc",
	syntax_comment = "#a08777",
	syntax_string = "#8f9b72",
	syntax_keyword = "#8fa383",
	syntax_function_name = "#769786",
	syntax_type = "#9c9974",
	syntax_property = "#858c86",
	syntax_literal = "#ad8e5b",
	diagnostic_error = "#c07872",
	version_control_conflict = "#b77a62",
}

return transform(simplified)
