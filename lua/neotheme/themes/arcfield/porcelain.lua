local transform = require("neotheme.themes.simplified").transform

---@type NeothemeSimplifiedPalette
local simplified = {
	surface_deepest = "#c9d7de",
	surface_dark = "#dbe6eb",
	surface_base = "#edf4f7",
	surface_raised = "#f9fcfd",
	surface_selected = "#c2dce7",
	surface_border = "#9fb8c4",
	surface_muted = "#778f9a",
	surface_addition = "#d2e8e2",
	surface_error = "#efd5de",
	text_primary = "#324650",
	text_bright = "#1d323c",
	text_strong = "#0d222c",
	text_muted = "#5b717c",
	text_on_accent = "#ffffff",
	text_on_error = "#481725",
	syntax_comment = "#5b717c",
	syntax_string = "#247763",
	syntax_keyword = "#006f91",
	syntax_function_name = "#315f9b",
	syntax_type = "#4b6477",
	syntax_property = "#6b603b",
	syntax_literal = "#826400",
	diagnostic_error = "#b53655",
	version_control_conflict = "#bd2e68",
}

return transform(simplified)
