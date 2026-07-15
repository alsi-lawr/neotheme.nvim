local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#c8bda9",
	surface_dark = "#d8cebb",
	surface_base = "#e9e0cd",
	surface_raised = "#f2ead9",
	surface_selected = "#d9ceb8",
	surface_border = "#b6aa96",
	surface_muted = "#938979",
	surface_addition = "#d5dacb",
	surface_error = "#dccbc4",
	text_primary = "#303638",
	text_bright = "#252a2c",
	text_strong = "#191d1f",
	text_muted = "#63635e",
	text_on_accent = "#f2e9d7",
	text_on_error = "#382522",
	syntax_comment = "#6a6256",
	syntax_string = "#5c594a",
	syntax_keyword = "#46545a",
	syntax_function_name = "#53515b",
	syntax_type = "#5a535e",
	syntax_property = "#4e5b58",
	syntax_literal = "#625749",
	diagnostic_error = "#7d3f3e",
	version_control_conflict = "#824b40",
}

return transform(simplified)
