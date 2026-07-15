local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#121211",
	surface_dark = "#1a1918",
	surface_base = "#242321",
	surface_raised = "#2e2c2a",
	surface_selected = "#403d39",
	surface_border = "#5b5650",
	surface_muted = "#77716a",
	surface_addition = "#2d3933",
	surface_error = "#4b2f30",
	text_primary = "#cbc4ba",
	text_bright = "#ded7cd",
	text_strong = "#f0e9df",
	text_muted = "#999188",
	text_on_accent = "#191817",
	text_on_error = "#f3ded9",
	syntax_comment = "#858079",
	syntax_string = "#aaa49c",
	syntax_keyword = "#d2d4d5",
	syntax_function_name = "#b8bdc0",
	syntax_type = "#99958f",
	syntax_property = "#c0b8ae",
	syntax_literal = "#969b9e",
	diagnostic_error = "#d98582",
	version_control_conflict = "#b77687",
}

return transform(simplified)
