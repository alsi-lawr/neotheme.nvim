local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#c7d3da",
	surface_dark = "#d8e1e6",
	surface_base = "#edf2f3",
	surface_raised = "#f8faf9",
	surface_selected = "#d5e3e7",
	surface_border = "#adbdc6",
	surface_muted = "#899da8",
	surface_addition = "#d7e8df",
	surface_error = "#e7cbcb",
	text_primary = "#263a48",
	text_bright = "#192b38",
	text_strong = "#0d1c27",
	text_muted = "#5d717c",
	text_on_accent = "#f7fafa",
	text_on_error = "#4b1e25",
	syntax_comment = "#697c86",
	syntax_string = "#4d735b",
	syntax_keyword = "#6e648f",
	syntax_function_name = "#3f7185",
	syntax_type = "#4f746e",
	syntax_property = "#5e6e84",
	syntax_literal = "#836157",
	diagnostic_error = "#a04853",
	version_control_conflict = "#ad5c61",
}

return transform(simplified)
