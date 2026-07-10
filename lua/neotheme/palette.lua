---@class NeothemeSurfacePalette
---@field deepest? string
---@field dark? string
---@field base? string
---@field raised? string
---@field selected? string
---@field border? string
---@field muted? string
---@field addition? string
---@field error? string

---@class NeothemeTextPalette
---@field primary? string
---@field bright? string
---@field strong? string
---@field muted? string
---@field on_accent? string
---@field on_error? string

---@class NeothemeSyntaxPalette
---@field comment? string
---@field string? string
---@field keyword? string
---@field function_name? string
---@field type? string
---@field property? string
---@field literal? string
---@field operator? string
---@field punctuation? string
---@field regexp? string
---@field special? string
---@field attribute? string
---@field tag? string

---@class NeothemeDiagnosticPalette
---@field error? string
---@field warning? string
---@field information? string
---@field hint? string
---@field success? string

---@class NeothemeMarkupPalette
---@field heading_1? string
---@field heading_2? string
---@field heading_3? string
---@field heading_4? string
---@field heading_5? string
---@field heading_6? string
---@field quote? string
---@field math? string
---@field link? string
---@field link_label? string
---@field raw? string
---@field list? string
---@field checked? string
---@field unchecked? string

---@class NeothemeVersionControlPalette
---@field added? string
---@field changed? string
---@field removed? string
---@field ignored? string
---@field conflict? string

---@class NeothemeUiPalette
---@field accent? string
---@field cursor? string
---@field directory? string
---@field search? string
---@field current_search? string
---@field match? string
---@field focus? string

---@class NeothemePalette
---@field surface NeothemeSurfacePalette
---@field text NeothemeTextPalette
---@field syntax NeothemeSyntaxPalette
---@field diagnostic NeothemeDiagnosticPalette
---@field markup NeothemeMarkupPalette
---@field version_control NeothemeVersionControlPalette
---@field ui NeothemeUiPalette

---@alias NeothemePaletteConfigurator fun(palette: NeothemePalette): nil

local schema = {
	surface = {
		"deepest",
		"dark",
		"base",
		"raised",
		"selected",
		"border",
		"muted",
		"addition",
		"error",
	},
	text = { "primary", "bright", "strong", "muted", "on_accent", "on_error" },
	syntax = {
		"comment",
		"string",
		"keyword",
		"function_name",
		"type",
		"property",
		"literal",
		"operator",
		"punctuation",
		"regexp",
		"special",
		"attribute",
		"tag",
	},
	diagnostic = { "error", "warning", "information", "hint", "success" },
	markup = {
		"heading_1",
		"heading_2",
		"heading_3",
		"heading_4",
		"heading_5",
		"heading_6",
		"quote",
		"math",
		"link",
		"link_label",
		"raw",
		"list",
		"checked",
		"unchecked",
	},
	version_control = { "added", "changed", "removed", "ignored", "conflict" },
	ui = { "accent", "cursor", "directory", "search", "current_search", "match", "focus" },
}

local function empty()
	local palette = {}
	for category in pairs(schema) do
		palette[category] = {}
	end
	return palette
end

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

local function validate(palette)
	for category, values in pairs(palette) do
		local fields = schema[category]
		if fields == nil then
			error(string.format("neotheme: unknown palette category %s", tostring(category)), 3)
		end
		if type(values) ~= "table" then
			error(string.format("neotheme: palette.%s must be a table", category), 3)
		end

		local known = {}
		for _, field in ipairs(fields) do
			known[field] = true
		end
		for field, color in pairs(values) do
			if not known[field] then
				error(string.format("neotheme: unknown palette entry %s.%s", category, tostring(field)), 3)
			end
			if type(color) ~= "string" or not color:match("^#%x%x%x%x%x%x$") then
				error(string.format("neotheme: palette.%s.%s must be a #RRGGBB color", category, field), 3)
			end
		end
	end

	for category in pairs(schema) do
		palette[category] = palette[category] or {}
	end
end

local function missing_paths(palette)
	local missing = {}
	for category, fields in pairs(schema) do
		for _, field in ipairs(fields) do
			if palette[category][field] == nil then
				table.insert(missing, category .. "." .. field)
			end
		end
	end
	table.sort(missing)
	return missing
end

local M = {}

---@return NeothemePalette
function M.empty()
	return empty()
end

---@param base NeothemePalette
---@param options NeothemeOptions
---@return NeothemePalette
function M.resolve(base, options)
	local palette = copy(base)
	if options.configure_palette then
		local returned = options.configure_palette(palette)
		if returned ~= nil then
			error("neotheme: configure_palette must mutate its palette argument and return nil", 2)
		end
	end

	validate(palette)
	local missing = missing_paths(palette)
	if #missing > 0 then
		vim.notify(
			string.format("neotheme: theme '%s' palette is missing entries: %s", options.theme, table.concat(missing, ", ")),
			vim.log.levels.WARN,
			{ title = "neotheme" }
		)
	end
	return copy(palette)
end

---@return string[]
function M.paths()
	return missing_paths(empty())
end

return M
