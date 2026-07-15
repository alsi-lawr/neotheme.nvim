local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#010306",
	surface_dark = "#03070b",
	surface_base = "#050b12",
	surface_raised = "#09131c",
	surface_selected = "#0f1d28",
	surface_border = "#192d39",
	surface_muted = "#526a7a",
	surface_addition = "#12382f",
	surface_error = "#5a2b36",
	text_primary = "#c5d5df",
	text_bright = "#e1eef4",
	text_strong = "#f2f8fa",
	text_muted = "#8299a8",
	text_on_accent = "#031018",
	text_on_error = "#fbecef",
	syntax_comment = "#627d8d",
	syntax_string = "#7db591",
	syntax_keyword = "#63b7c6",
	syntax_function_name = "#7f9ed1",
	syntax_type = "#9c8bc5",
	syntax_property = "#7893a5",
	syntax_literal = "#c38c99",
	diagnostic_error = "#d26975",
	version_control_conflict = "#b95664",
}

return transform(simplified)
