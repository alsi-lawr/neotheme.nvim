local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#d9d3cc",
	surface_dark = "#e4dfd8",
	surface_base = "#eeeae4",
	surface_raised = "#f5f1eb",
	surface_selected = "#ded8d0",
	surface_border = "#c5beb5",
	surface_muted = "#a9a198",
	surface_addition = "#dce5db",
	surface_error = "#e2bfbb",
	text_primary = "#4b4540",
	text_bright = "#37312d",
	text_strong = "#27221e",
	text_on_accent = "#2e2924",
	text_on_error = "#4a2522",
	syntax_comment = "#8b7562",
	syntax_string = "#5f8061",
	syntax_keyword = "#92743b",
	syntax_function_name = "#637b97",
	syntax_type = "#668078",
	syntax_property = "#7a838e",
	syntax_literal = "#7d7197",
	diagnostic_error = "#ad615c",
	version_control_conflict = "#b9706b",
}

return transform(simplified)
