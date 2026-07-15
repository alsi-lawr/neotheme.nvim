local modules = {
	["arcfield-graphite"] = { module = "neotheme.themes.arcfield.graphite", background = "dark" },
	["arcfield-porcelain"] = { module = "neotheme.themes.arcfield.porcelain", background = "light" },
	["arcfield-surge"] = { module = "neotheme.themes.arcfield.surge", background = "dark" },
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
