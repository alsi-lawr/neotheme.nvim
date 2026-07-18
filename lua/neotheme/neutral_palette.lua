local templates = {
	dark = {
		surface = {
			deepest = "#000000",
			dark = "#121212",
			base = "#1c1c1c",
			raised = "#262626",
			selected = "#3a3a3a",
			border = "#585858",
			muted = "#767676",
			addition = "#1f3d2b",
			error = "#d78787",
		},
		text = {
			primary = "#d0d0d0",
			bright = "#eeeeee",
			strong = "#ffffff",
			muted = "#9e9e9e",
			on_accent = "#000000",
			on_error = "#000000",
		},
		syntax = {
			comment = "#808080",
			string = "#87af87",
			keyword = "#af87af",
			function_name = "#87afd7",
			type = "#87afaf",
			property = "#d7af87",
			literal = "#d7af87",
			operator = "#d0d0d0",
			punctuation = "#bcbcbc",
			regexp = "#d78787",
			special = "#d7af5f",
			attribute = "#afafd7",
			tag = "#87afd7",
		},
		diagnostic = {
			error = "#d78787",
			warning = "#d7af5f",
			information = "#5fafd7",
			hint = "#87afaf",
			success = "#87af87",
		},
		markup = {
			heading_1 = "#af87af",
			heading_2 = "#87afd7",
			heading_3 = "#87afaf",
			heading_4 = "#d7af87",
			heading_5 = "#afafd7",
			heading_6 = "#9e9e9e",
			quote = "#808080",
			math = "#d7af87",
			link = "#87afd7",
			link_label = "#87afaf",
			raw = "#87af87",
			list = "#d7af5f",
			checked = "#87af87",
			unchecked = "#9e9e9e",
		},
		version_control = {
			added = "#87af87",
			changed = "#d7af5f",
			removed = "#d75f5f",
			ignored = "#767676",
			conflict = "#d78787",
		},
		ui = {
			accent = "#5fafd7",
			cursor = "#d0d0d0",
			directory = "#87afd7",
			search = "#d7af5f",
			current_search = "#d75f5f",
			match = "#87afaf",
			focus = "#af87af",
		},
	},
	light = {
		surface = {
			deepest = "#d7d7d7",
			dark = "#e4e4e4",
			base = "#f5f5f5",
			raised = "#ffffff",
			selected = "#d7e3f0",
			border = "#a8a8a8",
			muted = "#c6c6c6",
			addition = "#dcebdc",
			error = "#8b3030",
		},
		text = {
			primary = "#303030",
			bright = "#1c1c1c",
			strong = "#000000",
			muted = "#686868",
			on_accent = "#ffffff",
			on_error = "#ffffff",
		},
		syntax = {
			comment = "#707070",
			string = "#4f7f4f",
			keyword = "#7a3e7a",
			function_name = "#2f5f8f",
			type = "#3f6f6f",
			property = "#805f3f",
			literal = "#8a5a2b",
			operator = "#303030",
			punctuation = "#4a4a4a",
			regexp = "#9a4040",
			special = "#8a6500",
			attribute = "#65558f",
			tag = "#2f5f8f",
		},
		diagnostic = {
			error = "#b03030",
			warning = "#7a5900",
			information = "#2f5f8f",
			hint = "#386868",
			success = "#3f703f",
		},
		markup = {
			heading_1 = "#7a3e7a",
			heading_2 = "#2f5f8f",
			heading_3 = "#3f6f6f",
			heading_4 = "#805f3f",
			heading_5 = "#65558f",
			heading_6 = "#686868",
			quote = "#707070",
			math = "#8a5a2b",
			link = "#2f5f8f",
			link_label = "#3f6f6f",
			raw = "#4f7f4f",
			list = "#8a6500",
			checked = "#4f7f4f",
			unchecked = "#686868",
		},
		version_control = {
			added = "#4f7f4f",
			changed = "#8a6500",
			removed = "#b03030",
			ignored = "#888888",
			conflict = "#9a4040",
		},
		ui = {
			accent = "#2f5f8f",
			cursor = "#303030",
			directory = "#2f5f8f",
			search = "#6b5600",
			current_search = "#8a3f3f",
			match = "#326a6a",
			focus = "#7a3e7a",
		},
	},
}

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in pairs(value) do
		result[key] = copy(item)
	end
	return result
end

local M = {}

---@param background "dark"|"light"
---@return NeothemePalette
function M.get(background)
	local template = templates[background]
	if template == nil then
		error("neotheme: neutral palette background must be dark or light", 2)
	end
	return copy(template)
end

return M
