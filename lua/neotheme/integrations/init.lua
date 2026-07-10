local util = require("neotheme.highlights.util")

local M = {}

local names = {
	"nvim_tree",
	"cmp",
	"blink_cmp",
	"telescope",
	"fzf_lua",
	"gitsigns",
	"fugitive",
	"lspsaga",
	"rainbow_delimiters",
	"bufferline",
	"lazy",
	"which_key",
	"trouble",
	"noice",
	"snacks",
}

---@param enabled NeothemeIntegrationOptions
---@param palette NeothemePalette
function M.apply(enabled, palette)
	for _, name in ipairs(names) do
		if enabled[name] then
			util.apply(require("neotheme.integrations." .. name).get(palette))
		end
	end
end

return M
