local modules = {
	["gruber-darker"] = "neotheme.themes.gruber-darker",
	["gruber-muted"] = "neotheme.themes.gruber-muted",
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

	local module = modules[name]
	if not module then
		error(string.format("neotheme: unknown theme '%s'", name), 3)
	end
	return copy(require(module))
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
