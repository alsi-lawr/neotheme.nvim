---@class NeothemeItalicOptions
---@field comments boolean
---@field strings boolean
---@field folds boolean
---@field operators boolean

---@class NeothemeIntegrationOptions
---@field nvim_tree boolean
---@field cmp boolean
---@field blink_cmp boolean
---@field telescope boolean
---@field fzf_lua boolean
---@field gitsigns boolean
---@field fugitive boolean
---@field lspsaga boolean
---@field rainbow_delimiters boolean
---@field bufferline boolean
---@field lazy boolean
---@field which_key boolean
---@field trouble boolean
---@field noice boolean
---@field snacks boolean

---@class NeothemeOptions
---@field theme "arcfield-graphite"|"arcfield-porcelain"|"arcfield-surge"|"bathyal-bioluminescence"|"bathyal-marine-snow"|"bathyal-midwater"|"ferric-forge"|"ferric-patina"|"grove-campfire"|"grove-parchment"|"gruber-dark"|"gruber-dark-muted"|"gruber-darker"|"gruber-light"|"gruber-light-muted"|"gruber-lighter"|"neritic-bleached-day"|"neritic-bleached-night"|"neritic-day"|"neritic-night"|"typeset-ink"|"typeset-paper"|"typewriter-carbon"|"typewriter-ink"|"typewriter-low"|"typewriter-ribbon"|"typewriter-smudge"|"understory-canopy"|"understory-clearing"|"understory-dusk"|"understory-mist"|"custom"
---@field configure_palette? NeothemePaletteConfigurator
---@field bold boolean
---@field italic NeothemeItalicOptions
---@field underline boolean
---@field undercurl boolean
---@field integrations NeothemeIntegrationOptions

---@type NeothemeOptions
local defaults = {
	theme = "gruber-dark-muted",
	configure_palette = nil,
	bold = true,
	italic = {
		comments = true,
		strings = true,
		folds = true,
		operators = false,
	},
	underline = true,
	undercurl = true,
	integrations = {
		nvim_tree = false,
		cmp = false,
		blink_cmp = false,
		telescope = false,
		fzf_lua = false,
		gitsigns = false,
		fugitive = false,
		lspsaga = false,
		rainbow_delimiters = false,
		bufferline = false,
		lazy = false,
		which_key = false,
		trouble = false,
		noice = false,
		snacks = false,
	},
}

local schema = {
	theme = "string",
	configure_palette = "function",
	bold = "boolean",
	italic = {
		comments = "boolean",
		strings = "boolean",
		folds = "boolean",
		operators = "boolean",
	},
	underline = "boolean",
	undercurl = "boolean",
	integrations = {
		nvim_tree = "boolean",
		cmp = "boolean",
		blink_cmp = "boolean",
		telescope = "boolean",
		fzf_lua = "boolean",
		gitsigns = "boolean",
		fugitive = "boolean",
		lspsaga = "boolean",
		rainbow_delimiters = "boolean",
		bufferline = "boolean",
		lazy = "boolean",
		which_key = "boolean",
		trouble = "boolean",
		noice = "boolean",
		snacks = "boolean",
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

local function validate(options, expected, path)
	if type(options) ~= "table" then
		error(string.format("neotheme: %s must be a table", path), 3)
	end

	for key, value in pairs(options) do
		local rule = expected[key]
		local key_path = path .. "." .. tostring(key)
		if rule == nil then
			error(string.format("neotheme: unknown option %s", key_path), 3)
		elseif type(rule) == "string" then
			if type(value) ~= rule then
				error(string.format("neotheme: %s must be a %s", key_path, rule), 3)
			end
		else
			validate(value, rule, key_path)
		end
	end
end

local function merge(target, overrides)
	for key, value in pairs(overrides) do
		if type(value) == "table" then
			merge(target[key], value)
		else
			target[key] = value
		end
	end
	return target
end

local resolved = copy(defaults)
local M = {}

---@param options? NeothemeOptions
function M.setup(options)
	options = options or {}
	validate(options, schema, "options")
	resolved = merge(copy(defaults), options)
end

---@return NeothemeOptions
function M.get()
	return copy(resolved)
end

return M
