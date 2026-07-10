local M = {}

---@param p NeothemePalette
---@return table<string, NeothemeHighlight>
function M.get(p)
	return {
		RainbowDelimiterRed = { fg = p.diagnostic.error },
		RainbowDelimiterYellow = { fg = p.diagnostic.warning },
		RainbowDelimiterBlue = { fg = p.diagnostic.information },
		RainbowDelimiterOrange = { fg = p.syntax.comment },
		RainbowDelimiterGreen = { fg = p.diagnostic.success },
		RainbowDelimiterViolet = { fg = p.diagnostic.hint },
		RainbowDelimiterCyan = { fg = p.syntax.type },
	}
end

return M
