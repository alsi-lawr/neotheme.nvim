local M = {}

---@alias NeothemeHighlight table<string, boolean|integer|string>

---@param groups table<string, NeothemeHighlight>
function M.apply(groups)
	for name, highlight in pairs(groups) do
		vim.api.nvim_set_hl(0, name, highlight)
	end
end

return M
