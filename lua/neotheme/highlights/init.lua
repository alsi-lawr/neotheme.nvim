local util = require("neotheme.highlights.util")

local M = {}

---@param options NeothemeOptions
---@param palette NeothemePalette
function M.apply(options, palette)
	util.apply(require("neotheme.highlights.core").get(options, palette))
	util.apply(require("neotheme.highlights.treesitter").get(options, palette))
	util.apply(require("neotheme.highlights.lsp").get(options, palette))
	require("neotheme.highlights.terminal").apply(palette)

	local ok, integrations = pcall(require, "neotheme.integrations")
	if ok then
		integrations.apply(options.integrations, palette)
	end
end

---@param options NeothemeOptions
---@param palette NeothemePalette
---@param namespace integer
function M.apply_preview(options, palette, namespace)
	util.apply(require("neotheme.highlights.core").get(options, palette), namespace)
	util.apply(require("neotheme.highlights.treesitter").get(options, palette), namespace)
	util.apply(require("neotheme.highlights.lsp").get(options, palette), namespace)
end

return M
