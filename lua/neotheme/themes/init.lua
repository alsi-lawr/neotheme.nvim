local modules = {
	["arcfield-graphite"] = { module = "neotheme.themes.arcfield.graphite", background = "dark" },
	["arcfield-porcelain"] = { module = "neotheme.themes.arcfield.porcelain", background = "light" },
	["arcfield-surge"] = { module = "neotheme.themes.arcfield.surge", background = "dark" },
	["bathyal-bioluminescence"] = {
		module = "neotheme.themes.bathyal.bioluminescence",
		background = "dark",
	},
	["bathyal-marine-snow"] = {
		module = "neotheme.themes.bathyal.marine-snow",
		background = "light",
	},
	["bathyal-midwater"] = { module = "neotheme.themes.bathyal.midwater", background = "dark" },
	["ferric-forge"] = { module = "neotheme.themes.ferric.forge", background = "dark" },
	["ferric-patina"] = { module = "neotheme.themes.ferric.patina", background = "light" },
	["grove-campfire"] = { module = "neotheme.themes.grove.campfire", background = "dark" },
	["grove-parchment"] = {
		module = "neotheme.themes.grove.parchment",
		background = "light",
	},
	["gruber-dark"] = { module = "neotheme.themes.gruber.dark", background = "dark" },
	["gruber-dark-muted"] = { module = "neotheme.themes.gruber.dark-muted", background = "dark" },
	["gruber-darker"] = { module = "neotheme.themes.gruber.darker", background = "dark" },
	["gruber-light"] = { module = "neotheme.themes.gruber.light", background = "light" },
	["gruber-light-muted"] = { module = "neotheme.themes.gruber.light-muted", background = "light" },
	["gruber-lighter"] = { module = "neotheme.themes.gruber.lighter", background = "light" },
	["neritic-bleached-day"] = {
		module = "neotheme.themes.neritic.bleached-day",
		background = "light",
	},
	["neritic-bleached-night"] = {
		module = "neotheme.themes.neritic.bleached-night",
		background = "dark",
	},
	["neritic-day"] = { module = "neotheme.themes.neritic.day", background = "light" },
	["neritic-night"] = { module = "neotheme.themes.neritic.night", background = "dark" },
	["typeset-ink"] = { module = "neotheme.themes.typeset.ink", background = "dark" },
	["typeset-paper"] = { module = "neotheme.themes.typeset.paper", background = "light" },
	["typewriter-carbon"] = {
		module = "neotheme.themes.typewriter.carbon",
		background = "dark",
	},
	["typewriter-ink"] = { module = "neotheme.themes.typewriter.ink", background = "light" },
	["typewriter-low"] = { module = "neotheme.themes.typewriter.low", background = "light" },
	["typewriter-ribbon"] = {
		module = "neotheme.themes.typewriter.ribbon",
		background = "dark",
	},
	["typewriter-smudge"] = {
		module = "neotheme.themes.typewriter.smudge",
		background = "light",
	},
	["understory-canopy"] = {
		module = "neotheme.themes.understory.canopy",
		background = "dark",
	},
	["understory-clearing"] = {
		module = "neotheme.themes.understory.clearing",
		background = "light",
	},
	["understory-dusk"] = { module = "neotheme.themes.understory.dusk", background = "dark" },
	["understory-mist"] = { module = "neotheme.themes.understory.mist", background = "light" },
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

---@return string[]
function M.names()
	local names = { "custom" }
	for name in pairs(modules) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return M
