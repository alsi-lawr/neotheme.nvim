---@class NeothemeSimplifiedPalette
---@field surface_deepest string
---@field surface_dark string
---@field surface_base string
---@field surface_raised string
---@field surface_selected string
---@field surface_border string
---@field surface_muted string
---@field surface_addition string
---@field surface_error string
---@field text_primary string
---@field text_bright string
---@field text_strong string
---@field text_muted string
---@field text_on_accent string
---@field text_on_error string
---@field syntax_comment string
---@field syntax_string string
---@field syntax_keyword string
---@field syntax_function_name string
---@field syntax_type string
---@field syntax_property string
---@field syntax_literal string
---@field diagnostic_error string
---@field version_control_conflict string

local M = {}

local categories = {
	{
		key = "surface",
		label = "Surface",
		fields = {
			"surface_deepest",
			"surface_dark",
			"surface_base",
			"surface_raised",
			"surface_selected",
			"surface_border",
			"surface_muted",
			"surface_addition",
			"surface_error",
		},
	},
	{
		key = "text",
		label = "Text",
		fields = {
			"text_primary",
			"text_bright",
			"text_strong",
			"text_muted",
			"text_on_accent",
			"text_on_error",
		},
	},
	{
		key = "syntax",
		label = "Syntax",
		fields = {
			"syntax_comment",
			"syntax_string",
			"syntax_keyword",
			"syntax_function_name",
			"syntax_type",
			"syntax_property",
			"syntax_literal",
		},
	},
	{
		key = "signals",
		label = "Signals",
		fields = { "diagnostic_error", "version_control_conflict" },
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

local known_fields = {}
for _, category in ipairs(categories) do
	for _, field in ipairs(category.fields) do
		known_fields[field] = true
	end
end

---@return table[]
function M.categories()
	return copy(categories)
end

---@param simplified unknown
---@return boolean valid
---@return string? error_message
function M.is_complete(simplified)
	if type(simplified) ~= "table" then
		return false, "palette must be an object"
	end
	for _, category in ipairs(categories) do
		for _, field in ipairs(category.fields) do
			local color = simplified[field]
			if type(color) ~= "string" or not color:match("^#%x%x%x%x%x%x$") then
				return false, "palette." .. field .. " must be a #RRGGBB color"
			end
		end
	end
	local unknown = {}
	for field in pairs(simplified) do
		if not known_fields[field] then
			table.insert(unknown, tostring(field))
		end
	end
	table.sort(unknown)
	if #unknown > 0 then
		return false, "unknown palette entry " .. unknown[1]
	end
	return true
end

---@param simplified NeothemeSimplifiedPalette
---@return NeothemePalette
function M.transform(simplified)
	return {
		surface = {
			deepest = simplified.surface_deepest,
			dark = simplified.surface_dark,
			base = simplified.surface_base,
			raised = simplified.surface_raised,
			selected = simplified.surface_selected,
			border = simplified.surface_border,
			muted = simplified.surface_muted,
			addition = simplified.surface_addition,
			error = simplified.surface_error,
		},
		text = {
			primary = simplified.text_primary,
			bright = simplified.text_bright,
			strong = simplified.text_strong,
			muted = simplified.text_muted or simplified.syntax_type,
			on_accent = simplified.text_on_accent or simplified.surface_deepest,
			on_error = simplified.text_on_error,
		},
		syntax = {
			comment = simplified.syntax_comment,
			string = simplified.syntax_string,
			keyword = simplified.syntax_keyword,
			function_name = simplified.syntax_function_name,
			type = simplified.syntax_type,
			property = simplified.syntax_property,
			literal = simplified.syntax_literal,
			operator = simplified.syntax_keyword,
			punctuation = simplified.text_bright,
			regexp = simplified.diagnostic_error,
			special = simplified.diagnostic_error,
			attribute = simplified.syntax_type,
			tag = simplified.syntax_function_name,
		},
		diagnostic = {
			error = simplified.diagnostic_error,
			warning = simplified.syntax_keyword,
			information = simplified.syntax_function_name,
			hint = simplified.syntax_literal,
			success = simplified.syntax_string,
		},
		markup = {
			heading_1 = simplified.syntax_keyword,
			heading_2 = simplified.syntax_function_name,
			heading_3 = simplified.syntax_string,
			heading_4 = simplified.syntax_literal,
			heading_5 = simplified.syntax_type,
			heading_6 = simplified.syntax_comment,
			quote = simplified.syntax_comment,
			math = simplified.syntax_literal,
			link = simplified.syntax_function_name,
			link_label = simplified.syntax_keyword,
			raw = simplified.syntax_string,
			list = simplified.syntax_keyword,
			checked = simplified.syntax_string,
			unchecked = simplified.syntax_type,
		},
		version_control = {
			added = simplified.syntax_string,
			changed = simplified.syntax_keyword,
			removed = simplified.diagnostic_error,
			ignored = simplified.surface_muted,
			conflict = simplified.version_control_conflict,
		},
		ui = {
			accent = simplified.syntax_keyword,
			cursor = simplified.syntax_keyword,
			directory = simplified.syntax_function_name,
			search = simplified.syntax_keyword,
			current_search = simplified.text_on_error,
			match = simplified.syntax_literal,
			focus = simplified.text_strong,
		},
	}
end

return M
