local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#000102",
	surface_dark = "#010305",
	surface_base = "#020609",
	surface_raised = "#040b10",
	surface_selected = "#08141c",
	surface_border = "#101f2a",
	surface_muted = "#3c6672",
	surface_addition = "#073d34",
	surface_error = "#542532",
	text_primary = "#bed2db",
	text_bright = "#ddf0f2",
	text_strong = "#f1fcfa",
	text_muted = "#7493a0",
	text_on_accent = "#001417",
	text_on_error = "#fceef1",
	syntax_comment = "#507481",
	syntax_string = "#69c795",
	syntax_keyword = "#3cc6d5",
	syntax_function_name = "#579ad6",
	syntax_type = "#5eb7ae",
	syntax_property = "#6f8fa4",
	syntax_literal = "#a0c97a",
	diagnostic_error = "#e1626e",
	version_control_conflict = "#c94b59",
}

return transform(simplified)
