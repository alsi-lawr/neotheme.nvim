local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#0e0e0e",
	surface_dark = "#161616",
	surface_base = "#1d1d1d",
	surface_raised = "#262626",
	surface_selected = "#3c3935",
	surface_border = "#4a4743",
	surface_muted = "#635d54",
	surface_addition = "#29332e",
	surface_error = "#a6504c",
	text_primary = "#e4dfd7",
	text_bright = "#f4eee5",
	text_strong = "#fff8ef",
	text_on_error = "#fff6ed",
	syntax_comment = "#bf8a52",
	syntax_string = "#93c476",
	syntax_keyword = "#e8c05b",
	syntax_function_name = "#9eb1d1",
	syntax_type = "#9daf9e",
	syntax_property = "#8997a3",
	syntax_literal = "#ab9bc9",
	diagnostic_error = "#e06b63",
	version_control_conflict = "#ec7c72",
}

return transform(simplified)
