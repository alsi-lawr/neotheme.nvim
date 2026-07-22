local modules = {
	["arcfield-graphite"] = {
		module = "neotheme.themes.arcfield.graphite",
		background = "dark",
		family = "arcfield",
	},
	["arcfield-porcelain"] = {
		module = "neotheme.themes.arcfield.porcelain",
		background = "light",
		family = "arcfield",
	},
	["arcfield-surge"] = {
		module = "neotheme.themes.arcfield.surge",
		background = "dark",
		family = "arcfield",
	},
	["bathyal-bioluminescence"] = {
		module = "neotheme.themes.bathyal.bioluminescence",
		background = "dark",
		family = "bathyal",
	},
	["bathyal-marine-snow"] = {
		module = "neotheme.themes.bathyal.marine-snow",
		background = "light",
		family = "bathyal",
	},
	["bathyal-midwater"] = {
		module = "neotheme.themes.bathyal.midwater",
		background = "dark",
		family = "bathyal",
	},
	["ferric-forge"] = {
		module = "neotheme.themes.ferric.forge",
		background = "dark",
		family = "ferric",
	},
	["ferric-patina"] = {
		module = "neotheme.themes.ferric.patina",
		background = "light",
		family = "ferric",
	},
	["grove-campfire"] = {
		module = "neotheme.themes.grove.campfire",
		background = "dark",
		family = "grove",
	},
	["grove-parchment"] = {
		module = "neotheme.themes.grove.parchment",
		background = "light",
		family = "grove",
	},
	["gruber-dark"] = {
		module = "neotheme.themes.gruber.dark",
		background = "dark",
		family = "gruber",
	},
	["gruber-dark-muted"] = {
		module = "neotheme.themes.gruber.dark-muted",
		background = "dark",
		family = "gruber",
	},
	["gruber-darker"] = {
		module = "neotheme.themes.gruber.darker",
		background = "dark",
		family = "gruber",
	},
	["gruber-light"] = {
		module = "neotheme.themes.gruber.light",
		background = "light",
		family = "gruber",
	},
	["gruber-light-muted"] = {
		module = "neotheme.themes.gruber.light-muted",
		background = "light",
		family = "gruber",
	},
	["gruber-lighter"] = {
		module = "neotheme.themes.gruber.lighter",
		background = "light",
		family = "gruber",
	},
	["neritic-bleached-day"] = {
		module = "neotheme.themes.neritic.bleached-day",
		background = "light",
		family = "neritic",
	},
	["neritic-bleached-night"] = {
		module = "neotheme.themes.neritic.bleached-night",
		background = "dark",
		family = "neritic",
	},
	["neritic-day"] = {
		module = "neotheme.themes.neritic.day",
		background = "light",
		family = "neritic",
	},
	["neritic-night"] = {
		module = "neotheme.themes.neritic.night",
		background = "dark",
		family = "neritic",
	},
	["typeset-ink"] = {
		module = "neotheme.themes.typeset.ink",
		background = "dark",
		family = "typeset",
	},
	["typeset-paper"] = {
		module = "neotheme.themes.typeset.paper",
		background = "light",
		family = "typeset",
	},
	["typewriter-carbon"] = {
		module = "neotheme.themes.typewriter.carbon",
		background = "dark",
		family = "typewriter",
	},
	["typewriter-ink"] = {
		module = "neotheme.themes.typewriter.ink",
		background = "light",
		family = "typewriter",
	},
	["typewriter-low"] = {
		module = "neotheme.themes.typewriter.low",
		background = "light",
		family = "typewriter",
	},
	["typewriter-ribbon"] = {
		module = "neotheme.themes.typewriter.ribbon",
		background = "dark",
		family = "typewriter",
	},
	["typewriter-smudge"] = {
		module = "neotheme.themes.typewriter.smudge",
		background = "light",
		family = "typewriter",
	},
	["understory-canopy"] = {
		module = "neotheme.themes.understory.canopy",
		background = "dark",
		family = "understory",
	},
	["understory-clearing"] = {
		module = "neotheme.themes.understory.clearing",
		background = "light",
		family = "understory",
	},
	["understory-dusk"] = {
		module = "neotheme.themes.understory.dusk",
		background = "dark",
		family = "understory",
	},
	["understory-mist"] = {
		module = "neotheme.themes.understory.mist",
		background = "light",
		family = "understory",
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

local function expand_record(record)
	if record.mode == "simplified" then
		return require("neotheme.themes.simplified").transform(copy(record.palette))
	end
	return copy(record.palette)
end

local bundled_families = {}
for _, theme in pairs(modules) do
	bundled_families[theme.family] = true
end

local function user_inventory()
	local state = require("neotheme.state").load()
	local families = {}
	for name, record in pairs(state.families) do
		families[name] = { enabled = record.enabled, user = not bundled_families[name] }
	end
	for _, theme in pairs(modules) do
		if families[theme.family] == nil then
			families[theme.family] = { enabled = true, user = false }
		end
	end

	local themes = {}
	for name, record in pairs(state.themes) do
		if modules[name] ~= nil then
			table.insert(
				state.diagnostics,
				"palettes/"
					.. record.family
					.. "/"
					.. name
					.. ".json: name collides with a bundled theme"
			)
		elseif families[record.family] == nil then
			table.insert(
				state.diagnostics,
				"palettes/" .. record.family .. "/" .. name .. ".json: family does not exist"
			)
		else
			themes[name] = record
		end
	end
	table.sort(state.diagnostics)
	return families, themes, state.diagnostics
end

local function provider_inventory(candidate)
	return require("neotheme.providers").get(candidate)
end

function M._prepare_providers(configured)
	local families, themes = user_inventory()
	return require("neotheme.providers").prepare(configured, modules, families, themes)
end

function M._commit_providers(candidate)
	require("neotheme.providers").commit(candidate)
end

---@param name string
---@return NeothemePalette
function M.get(name, candidate)
	if name == "custom" then
		return require("neotheme.palette").empty()
	end

	local theme = modules[name]
	if theme then
		return copy(require(theme.module))
	end
	local provider_theme = provider_inventory(candidate).themes[name]
	if provider_theme then
		return expand_record(provider_theme)
	end
	local _, user_themes = user_inventory()
	local user_theme = user_themes[name]
	if not user_theme then
		error(string.format("neotheme: unknown theme '%s'", name), 3)
	end
	return expand_record(user_theme)
end

---@param record table
---@return NeothemePalette
function M.expand(record)
	return expand_record(record)
end

---@param name string
---@return "dark"|"light"
function M.background(name, candidate)
	if name == "custom" then
		return "dark"
	end

	local theme = modules[name]
	if theme then
		return theme.background
	end
	local provider_theme = provider_inventory(candidate).themes[name]
	if provider_theme then
		return provider_theme.background
	end
	local _, user_themes = user_inventory()
	local user_theme = user_themes[name]
	if not user_theme then
		error(string.format("neotheme: unknown theme '%s'", name), 3)
	end
	return user_theme.background
end

---@param name string
---@return string?
function M.family(name)
	if name == "custom" then
		return nil
	end

	local theme = modules[name]
	if theme then
		return theme.family
	end
	local provider_theme = provider_inventory().themes[name]
	if provider_theme then
		return provider_theme.family
	end
	local _, user_themes = user_inventory()
	local user_theme = user_themes[name]
	if not user_theme then
		error(string.format("neotheme: unknown theme '%s'", name), 3)
	end
	return user_theme.family
end

---@param family? string
---@return string[]
function M.names(family)
	local families, user_themes = user_inventory()
	local names = family == nil and { "custom" } or {}
	if family ~= nil and families[family] == nil then
		error(string.format("neotheme: unknown family '%s'", family), 3)
	end

	for name, theme in pairs(modules) do
		if
			(family == nil and families[theme.family].enabled)
			or (family == theme.family and families[family].enabled)
		then
			table.insert(names, name)
		end
	end
	for name, theme in pairs(user_themes) do
		if
			(family == nil and families[theme.family].enabled)
			or (family == theme.family and families[family].enabled)
		then
			table.insert(names, name)
		end
	end

	table.sort(names)
	return names
end

---@return string[]
function M.families()
	local inventory, user_themes = user_inventory()
	local families = {}
	local has_theme = {}
	for _, theme in pairs(modules) do
		has_theme[theme.family] = true
	end
	for _, theme in pairs(user_themes) do
		has_theme[theme.family] = true
	end

	for name, record in pairs(inventory) do
		if record.enabled and has_theme[name] then
			table.insert(families, name)
		end
	end

	table.sort(families)
	return families
end

---@return string[] families
---@return table<string, string[]> themes_by_family
---@return string[] diagnostics
function M.inventory()
	local families, user_themes, diagnostics = user_inventory()
	local names = {}
	local by_family = {}
	for family in pairs(families) do
		by_family[family] = {}
		table.insert(names, family)
	end
	for name, theme in pairs(modules) do
		table.insert(by_family[theme.family], name)
	end
	for name, theme in pairs(user_themes) do
		table.insert(by_family[theme.family], name)
	end
	for _, values in pairs(by_family) do
		table.sort(values)
	end
	table.sort(names)
	return names, by_family, diagnostics
end

---@param name string
---@return boolean
function M.is_user(name)
	local _, themes = user_inventory()
	return themes[name] ~= nil
end

---@param name string
---@return boolean
function M.is_builtin(name)
	return modules[name] ~= nil
end

---@param name string
---@return boolean
function M.family_exists(name)
	local families = user_inventory()
	return families[name] ~= nil
end

---@param name string
---@return boolean
function M.family_enabled(name)
	local families = user_inventory()
	return families[name] ~= nil and families[name].enabled
end

---@param name string
---@return boolean
function M.is_user_family(name)
	local families = user_inventory()
	return families[name] ~= nil and families[name].user
end

---@param name string
function M.create_family(name)
	if modules[name] ~= nil then
		error("neotheme: a bundled theme already uses the family name '" .. name .. "'", 2)
	end
	local families = user_inventory()
	if families[name] ~= nil then
		error("neotheme: family '" .. name .. "' already exists", 2)
	end
	require("neotheme.state").write_family(name, true)
end

---@param name string
---@param enabled boolean
function M.set_family_enabled(name, enabled)
	local families = user_inventory()
	if families[name] == nil then
		error("neotheme: unknown family '" .. name .. "'", 2)
	end
	require("neotheme.state").write_family(name, enabled)
end

---@param name string
function M.delete_family(name)
	local families = user_inventory()
	local family = families[name]
	if family == nil then
		error("neotheme: unknown family '" .. tostring(name) .. "'", 2)
	end
	if not family.user then
		error("neotheme: bundled family '" .. name .. "' cannot be deleted", 2)
	end
	if require("neotheme.state").family_has_theme_files(name) then
		error("neotheme: family '" .. name .. "' is not empty; delete its user themes first", 2)
	end
	require("neotheme.state").delete_family(name)
end

local function validate_clone_target(family, name)
	if not M.family_exists(family) then
		error("neotheme: unknown family '" .. family .. "'", 2)
	end
	if name == "custom" or modules[name] ~= nil or M.is_user(name) then
		error("neotheme: theme '" .. name .. "' already exists", 2)
	end
end

local function write_clone(snapshot, family, name)
	local record = {
		version = 2,
		family = family,
		name = name,
		background = type(snapshot) == "table" and snapshot.background or nil,
		mode = type(snapshot) == "table" and snapshot.mode or "full",
		palette = type(snapshot) == "table" and copy(snapshot.palette) or nil,
	}
	return require("neotheme.state").write_theme(record)
end

---@param snapshot table
---@param family string
---@param name string
---@return table record
function M.create_snapshot(snapshot, family, name)
	validate_clone_target(family, name)
	return write_clone(snapshot, family, name)
end

---@param source string
---@param family string
---@param name string
---@return table record
function M.clone(source, family, name)
	validate_clone_target(family, name)
	local _, user_themes = user_inventory()
	local user_theme = user_themes[source]
	if user_theme then
		return write_clone({
			background = user_theme.background,
			mode = user_theme.mode,
			palette = user_theme.palette,
		}, family, name)
	end
	return write_clone(
		{ background = M.background(source), mode = "full", palette = M.get(source) },
		family,
		name
	)
end

---@param record table
function M.save(record)
	if not M.is_user(record.name) then
		error("neotheme: bundled themes are read-only templates", 2)
	end
	if not M.family_exists(record.family) then
		error("neotheme: unknown family '" .. tostring(record.family) .. "'", 2)
	end
	return require("neotheme.state").write_theme(record)
end

---@param name string
function M.delete_theme(name)
	if modules[name] ~= nil then
		error("neotheme: bundled theme '" .. name .. "' cannot be deleted", 2)
	end
	local _, user_themes = user_inventory()
	local record = user_themes[name]
	if record == nil then
		error("neotheme: unknown user theme '" .. tostring(name) .. "'", 2)
	end
	if require("neotheme.config").get().theme == name then
		error("neotheme: configured theme '" .. name .. "' cannot be deleted", 2)
	end
	local engine = require("neotheme")
	local current = engine.current()
	if current.active_theme == name then
		error("neotheme: active theme '" .. name .. "' cannot be deleted", 2)
	end
	if engine._retains_session_theme(name) then
		error(
			"neotheme: session override theme '"
				.. name
				.. "' cannot be deleted; run :NeothemeReset before deleting it",
			2
		)
	end
	require("neotheme.state").delete_theme(record.family, name)
end

return M
