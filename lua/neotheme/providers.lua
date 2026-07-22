local palette = require("neotheme.palette")
local simplified = require("neotheme.themes.simplified")

local M = {}
local active = { families = {}, themes = {}, providers = {} }
local slug_pattern = "^[a-z0-9]+[a-z0-9-]*$"

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in pairs(value) do
		result[copy(key)] = copy(item)
	end
	return result
end

local function exact_keys(value, expected, path)
	if type(value) ~= "table" then
		error("neotheme: " .. path .. " must be a table", 3)
	end
	for key in pairs(value) do
		if not expected[key] then
			error("neotheme: unknown field " .. path .. "." .. tostring(key), 3)
		end
	end
	for key in pairs(expected) do
		if value[key] == nil then
			error("neotheme: missing field " .. path .. "." .. key, 3)
		end
	end
end

local function slug(value, path)
	if type(value) ~= "string" or not value:match(slug_pattern) then
		error("neotheme: " .. path .. " must be a lowercase ASCII slug", 3)
	end
end

function M.prepare(configured, builtins, user_families, user_themes)
	local candidate = { families = {}, themes = {}, providers = {} }
	local occupied_families = { custom = true }
	local occupied_themes = { custom = true }
	for _, record in pairs(builtins) do
		occupied_families[record.family] = true
	end
	for name in pairs(builtins) do
		occupied_themes[name] = true
	end
	for name in pairs(user_families) do
		occupied_families[name] = true
	end
	for name in pairs(user_themes) do
		occupied_themes[name] = true
	end

	for _, request in ipairs(configured) do
		local ok, returned = pcall(require, request.provider)
		if not ok then
			error(
				"neotheme: failed to load palette provider '"
					.. request.provider
					.. "': "
					.. tostring(returned),
				2
			)
		end
		local provider = copy(returned)
		exact_keys(
			provider,
			{ version = true, provider = true, packs = true },
			"provider " .. request.provider
		)
		if provider.version ~= 1 then
			error("neotheme: provider '" .. request.provider .. "' has unsupported version", 2)
		end
		slug(provider.provider, "provider identity")
		if candidate.providers[provider.provider] then
			error("neotheme: duplicate provider identity '" .. provider.provider .. "'", 2)
		end
		candidate.providers[provider.provider] = true
		if type(provider.packs) ~= "table" then
			error("neotheme: provider packs must be a table", 2)
		end
		local selected = {}
		if request.include == "*" then
			for name in pairs(provider.packs) do
				selected[name] = true
			end
		else
			for _, name in ipairs(request.include) do
				if provider.packs[name] == nil then
					error(
						"neotheme: provider '"
							.. provider.provider
							.. "' has no pack '"
							.. name
							.. "'",
						2
					)
				end
				selected[name] = true
			end
		end
		for pack_name in pairs(selected) do
			slug(pack_name, "pack name")
			local pack = provider.packs[pack_name]
			exact_keys(pack, { family = true, themes = true }, "pack " .. pack_name)
			slug(pack.family, "pack family")
			if pack.family ~= pack_name then
				error("neotheme: pack '" .. pack_name .. "' family must match its key", 2)
			end
			if occupied_families[pack_name] then
				error("neotheme: palette pack family collision '" .. pack_name .. "'", 2)
			end
			occupied_families[pack_name] = true
			candidate.families[pack_name] = { enabled = true, provider = provider.provider }
			if type(pack.themes) ~= "table" then
				error("neotheme: pack themes must be a table", 2)
			end
			for theme_name, theme in pairs(pack.themes) do
				slug(theme_name, "provider theme name")
				exact_keys(
					theme,
					{ background = true, mode = true, palette = true },
					"theme " .. theme_name
				)
				if theme.background ~= "dark" and theme.background ~= "light" then
					error("neotheme: theme background must be dark or light", 2)
				end
				if theme.mode ~= "full" and theme.mode ~= "simplified" then
					error("neotheme: theme mode must be full or simplified", 2)
				end
				local valid, message = (theme.mode == "full" and palette or simplified).is_complete(
					theme.palette
				)
				if not valid then
					error(
						"neotheme: invalid provider theme '"
							.. theme_name
							.. "': "
							.. tostring(message),
						2
					)
				end
				if occupied_themes[theme_name] then
					error("neotheme: palette pack theme collision '" .. theme_name .. "'", 2)
				end
				occupied_themes[theme_name] = true
				candidate.themes[theme_name] = {
					family = pack_name,
					provider = provider.provider,
					background = theme.background,
					mode = theme.mode,
					palette = copy(theme.palette),
				}
			end
		end
	end
	return candidate
end

function M.commit(candidate)
	active = copy(candidate)
end
function M.get(candidate)
	return copy(candidate or active)
end

return M
