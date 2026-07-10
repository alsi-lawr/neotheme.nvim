local surface_deepest = "#000000"
local surface_dark = "#101010"
local surface_base = "#181818"
local surface_raised = "#282828"
local surface_selected = "#453d41"
local surface_border = "#484848"
local surface_muted = "#52494e"
local surface_addition = "#303540"
local surface_error = "#c73c3f"
local text_primary = "#e4e4e4"
local text_bright = "#f4f4ff"
local text_strong = "#f5f5f5"
local text_on_error = "#ffffff"
local syntax_comment = "#cc8c3c"
local syntax_string = "#73d936"
local syntax_keyword = "#ffdd33"
local syntax_function = "#96a6c8"
local syntax_type = "#95a99f"
local syntax_property = "#565f73"
local syntax_literal = "#9e95c7"
local diagnostic_error = "#f43841"
local version_control_conflict = "#ff4f58"

---@type NeothemePalette
return {
	surface = {
		deepest = surface_deepest,
		dark = surface_dark,
		base = surface_base,
		raised = surface_raised,
		selected = surface_selected,
		border = surface_border,
		muted = surface_muted,
		addition = surface_addition,
		error = surface_error,
	},
	text = {
		primary = text_primary,
		bright = text_bright,
		strong = text_strong,
		muted = syntax_type,
		on_accent = surface_deepest,
		on_error = text_on_error,
	},
	syntax = {
		comment = syntax_comment,
		string = syntax_string,
		keyword = syntax_keyword,
		function_name = syntax_function,
		type = syntax_type,
		property = syntax_property,
		literal = syntax_literal,
		operator = syntax_keyword,
		punctuation = text_bright,
		regexp = diagnostic_error,
		special = diagnostic_error,
		attribute = syntax_type,
		tag = syntax_function,
	},
	diagnostic = {
		error = diagnostic_error,
		warning = syntax_keyword,
		information = syntax_function,
		hint = syntax_literal,
		success = syntax_string,
	},
	markup = {
		heading_1 = syntax_keyword,
		heading_2 = syntax_function,
		heading_3 = syntax_string,
		heading_4 = syntax_literal,
		heading_5 = syntax_type,
		heading_6 = syntax_comment,
		quote = syntax_comment,
		math = syntax_literal,
		link = syntax_function,
		link_label = syntax_keyword,
		raw = syntax_string,
		list = syntax_keyword,
		checked = syntax_string,
		unchecked = syntax_type,
	},
	version_control = {
		added = syntax_string,
		changed = syntax_keyword,
		removed = diagnostic_error,
		ignored = surface_muted,
		conflict = version_control_conflict,
	},
	ui = {
		accent = syntax_keyword,
		cursor = syntax_keyword,
		directory = syntax_function,
		search = syntax_keyword,
		current_search = text_on_error,
		match = syntax_literal,
		focus = text_strong,
	},
}
