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

---@class NeothemeMotionOptions
---@field level "interpolate"|"winblend"
---@field duration_ms integer

---@class NeothemeOptions
---@field theme "arcfield-graphite"|"arcfield-porcelain"|"arcfield-surge"|"bathyal-bioluminescence"|"bathyal-marine-snow"|"bathyal-midwater"|"ferric-forge"|"ferric-patina"|"grove-campfire"|"grove-parchment"|"gruber-dark"|"gruber-dark-muted"|"gruber-darker"|"gruber-light"|"gruber-light-muted"|"gruber-lighter"|"neritic-bleached-day"|"neritic-bleached-night"|"neritic-day"|"neritic-night"|"typeset-ink"|"typeset-paper"|"typewriter-carbon"|"typewriter-ink"|"typewriter-low"|"typewriter-ribbon"|"typewriter-smudge"|"understory-canopy"|"understory-clearing"|"understory-dusk"|"understory-mist"|"custom"
---@field palette_packs NeothemePalettePackOptions[]
---@field motion false|NeothemeMotionOptions
---@field configure_palette? NeothemePaletteConfigurator
---@field bold boolean
---@field italic NeothemeItalicOptions
---@field underline boolean
---@field undercurl boolean
---@field integrations NeothemeIntegrationOptions

---@type NeothemeOptions
local defaults = {
	theme = "gruber-dark-muted",
	palette_packs = {},
	motion = {
		level = "interpolate",
		duration_ms = 500,
	},
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

local motion_schema = {
	level = "string",
	duration_ms = "number",
}

local schema = {
	theme = "string",
	palette_packs = "table",
	motion = motion_schema,
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

local motion_levels = {
	winblend = true,
	interpolate = true,
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
			if rule ~= motion_schema or value ~= false then
				validate(value, rule, key_path)
			end
		end
	end
end

local function merge(target, overrides)
	for key, value in pairs(overrides) do
		if type(value) == "table" then
			if target[key] == nil or vim.islist(value) then
				target[key] = copy(value)
			else
				merge(target[key], value)
			end
		else
			target[key] = value
		end
	end
	return target
end

local function validate_palette_packs(value)
	local seen = {}
	for index, entry in ipairs(value) do
		if type(entry) ~= "table" then
			error(string.format("neotheme: options.palette_packs.%d must be a table", index), 3)
		end
		for key in pairs(entry) do
			if key ~= "provider" and key ~= "include" then
				error(
					string.format(
						"neotheme: unknown option options.palette_packs.%d.%s",
						index,
						tostring(key)
					),
					3
				)
			end
		end
		if type(entry.provider) ~= "string" or entry.provider == "" then
			error(
				string.format(
					"neotheme: options.palette_packs.%d.provider must be a non-empty string",
					index
				),
				3
			)
		end
		if seen[entry.provider] then
			error("neotheme: duplicate palette pack provider '" .. entry.provider .. "'", 3)
		end
		seen[entry.provider] = true
		if entry.include ~= "*" then
			if type(entry.include) ~= "table" then
				error(
					string.format(
						"neotheme: options.palette_packs.%d.include must be '*' or a family array",
						index
					),
					3
				)
			end
			local included = {}
			for family_index, family in ipairs(entry.include) do
				if type(family) ~= "string" or family == "" then
					error(
						string.format(
							"neotheme: options.palette_packs.%d.include.%d must be a non-empty string",
							index,
							family_index
						),
						3
					)
				end
				if included[family] then
					error("neotheme: duplicate included family '" .. family .. "'", 3)
				end
				included[family] = true
			end
			if #entry.include ~= vim.tbl_count(entry.include) then
				error(
					string.format(
						"neotheme: options.palette_packs.%d.include must be an array",
						index
					),
					3
				)
			end
		end
	end
	if #value ~= vim.tbl_count(value) then
		error("neotheme: options.palette_packs must be an array", 3)
	end
end

local resolved = copy(defaults)
local M = {}

---@param options? NeothemeOptions
---@return NeothemeOptions
function M._prepare(options)
	options = options or {}
	validate(options, schema, "options")
	if options.palette_packs ~= nil then
		validate_palette_packs(options.palette_packs)
	end
	if options.motion ~= nil and options.motion ~= false then
		if options.motion.level ~= nil and not motion_levels[options.motion.level] then
			error("neotheme: options.motion.level must be one of: interpolate, winblend", 2)
		end
		if options.motion.duration_ms ~= nil then
			local duration = options.motion.duration_ms
			if duration < 1 or duration % 1 ~= 0 then
				error("neotheme: options.motion.duration_ms must be a positive integer", 2)
			end
		end
	end
	return merge(copy(defaults), options)
end

---@param options NeothemeOptions
function M._commit(options)
	resolved = copy(options)
end

---@param options? NeothemeOptions
function M.setup(options)
	M._commit(M._prepare(options))
end

---@return NeothemeOptions
function M.get()
	return copy(resolved)
end

return M
