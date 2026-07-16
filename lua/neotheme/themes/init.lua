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

---@param name string
---@return NeothemePalette
function M.get(name)
	if name == "custom" then
		return require("neotheme.palette").empty()
	end

	local theme = modules[name]
	if not theme then
		error(string.format("neotheme: unknown theme '%s'", name), 3)
	end
	return copy(require(theme.module))
end

---@param name string
---@return "dark"|"light"
function M.background(name)
	if name == "custom" then
		return "dark"
	end

	local theme = modules[name]
	if not theme then
		error(string.format("neotheme: unknown theme '%s'", name), 3)
	end
	return theme.background
end

---@param name string
---@return string?
function M.family(name)
	if name == "custom" then
		return nil
	end

	local theme = modules[name]
	if not theme then
		error(string.format("neotheme: unknown theme '%s'", name), 3)
	end
	return theme.family
end

---@param family? string
---@return string[]
function M.names(family)
	local names = family == nil and { "custom" } or {}
	local family_exists = family == nil

	for name, theme in pairs(modules) do
		if family == nil or theme.family == family then
			table.insert(names, name)
			family_exists = true
		end
	end

	if not family_exists then
		error(string.format("neotheme: unknown family '%s'", family), 3)
	end

	table.sort(names)
	return names
end

---@return string[]
function M.families()
	local seen = {}
	local families = {}

	for _, theme in pairs(modules) do
		if not seen[theme.family] then
			seen[theme.family] = true
			table.insert(families, theme.family)
		end
	end

	table.sort(families)
	return families
end

return M
