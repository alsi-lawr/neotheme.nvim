local surface_deepest = "#000000"
local surface_dark = "#101010"
local surface_base = "#202020"
local surface_raised = "#282828"
local surface_selected = "#453d41"
local surface_border = "#484848"
local surface_muted = "#52494e"
local surface_addition = "#30343a"
local surface_error = "#9f5553"
local text_primary = "#d1c9c0"
local text_bright = "#d9d1c7"
local text_strong = "#e8ded2"
local text_on_error = "#f3eadf"
local syntax_comment = "#ad835e"
local syntax_string = "#9bb875"
local syntax_keyword = "#c9ae68"
local syntax_function = "#8b99aa"
local syntax_type = "#8fa099"
local syntax_property = "#74818f"
local syntax_literal = "#968aa8"
local diagnostic_error = "#d07872"
local version_control_conflict = "#bd6562"

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
