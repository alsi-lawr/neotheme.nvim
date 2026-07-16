local M = {}

---@alias NeothemeHighlight table<string, boolean|integer|string>

---@param groups table<string, NeothemeHighlight>
---@param namespace? integer
function M.apply(groups, namespace)
	for name, highlight in pairs(groups) do
		vim.api.nvim_set_hl(namespace or 0, name, highlight)
	end
end

return M
