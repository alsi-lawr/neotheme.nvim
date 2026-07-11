local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#000000",
	surface_dark = "#101010",
	surface_base = "#181818",
	surface_raised = "#282828",
	surface_selected = "#453d41",
	surface_border = "#484848",
	surface_muted = "#52494e",
	surface_addition = "#303540",
	surface_error = "#c73c3f",
	text_primary = "#e4e4e4",
	text_bright = "#f4f4ff",
	text_strong = "#f5f5f5",
	text_on_error = "#ffffff",
	syntax_comment = "#cc8c3c",
	syntax_string = "#73d936",
	syntax_keyword = "#ffdd33",
	syntax_function_name = "#96a6c8",
	syntax_type = "#95a99f",
	syntax_property = "#565f73",
	syntax_literal = "#9e95c7",
	diagnostic_error = "#f43841",
	version_control_conflict = "#ff4f58",
}

return transform(simplified)
