local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#c4d0be",
	surface_dark = "#d4decf",
	surface_base = "#e5ebdd",
	surface_raised = "#f2f4e8",
	surface_selected = "#cedbc8",
	surface_border = "#aabdaa",
	surface_muted = "#7f9889",
	surface_addition = "#cee2cf",
	surface_error = "#e3beb5",
	text_primary = "#213b2d",
	text_bright = "#153024",
	text_strong = "#0b2419",
	text_muted = "#536d5f",
	text_on_accent = "#f5f9f2",
	text_on_error = "#47231f",
	syntax_comment = "#765a45",
	syntax_string = "#5a6d32",
	syntax_keyword = "#3d6e47",
	syntax_function_name = "#32705b",
	syntax_type = "#6a6c2f",
	syntax_property = "#625f55",
	syntax_literal = "#8b6019",
	diagnostic_error = "#a9443e",
	version_control_conflict = "#b7583f",
}

return transform(simplified)
