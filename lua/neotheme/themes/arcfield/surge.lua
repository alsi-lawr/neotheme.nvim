local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#010207",
	surface_dark = "#03050c",
	surface_base = "#060912",
	surface_raised = "#0e1425",
	surface_selected = "#202b42",
	surface_border = "#39465f",
	surface_muted = "#698895",
	surface_addition = "#103b37",
	surface_error = "#5a263e",
	text_primary = "#d9edf4",
	text_bright = "#f0fbff",
	text_strong = "#ffffff",
	text_muted = "#92acb7",
	text_on_accent = "#021017",
	text_on_error = "#ffffff",
	syntax_comment = "#76939f",
	syntax_string = "#4cc9a5",
	syntax_keyword = "#2de2ff",
	syntax_function_name = "#a6d9ff",
	syntax_type = "#7faec9",
	syntax_property = "#ead58e",
	syntax_literal = "#ffe06a",
	diagnostic_error = "#ff557e",
	version_control_conflict = "#ff2e78",
}

return transform(simplified)
