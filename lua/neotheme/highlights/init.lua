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

return M
