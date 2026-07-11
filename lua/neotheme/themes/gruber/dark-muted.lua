local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#000000",
	surface_dark = "#101010",
	surface_base = "#202020",
	surface_raised = "#282828",
	surface_selected = "#453d41",
	surface_border = "#484848",
	surface_muted = "#52494e",
	surface_addition = "#30343a",
	surface_error = "#9f5553",
	text_primary = "#d1c9c0",
	text_bright = "#d9d1c7",
	text_strong = "#e8ded2",
	text_on_error = "#f3eadf",
	syntax_comment = "#ad835e",
	syntax_string = "#9bb875",
	syntax_keyword = "#c9ae68",
	syntax_function_name = "#8b99aa",
	syntax_type = "#8fa099",
	syntax_property = "#74818f",
	syntax_literal = "#968aa8",
	diagnostic_error = "#d07872",
	version_control_conflict = "#bd6562",
}

return transform(simplified)
