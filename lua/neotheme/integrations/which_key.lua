local M = {}

---@param p NeothemePalette
---@return table<string, NeothemeHighlight>
function M.get(p)
	return {
		WhichKeyNormal = { link = "NormalFloat" },
		WhichKeyTitle = { link = "FloatTitle" },
		WhichKeyBorder = { link = "FloatBorder" },
		WhichKey = { fg = p.diagnostic.information },
		WhichKeyDesc = { fg = p.text.bright },
		WhichKeyGroup = { fg = p.ui.accent },
		WhichKeyIcon = { fg = p.text.muted },
		WhichKeyIconAzure = { fg = p.diagnostic.information },
		WhichKeyIconBlue = { fg = p.syntax.property },
		WhichKeyIconCyan = { fg = p.syntax.type },
		WhichKeyIconGreen = { fg = p.diagnostic.success },
		WhichKeyIconGrey = { fg = p.version_control.ignored },
		WhichKeyIconOrange = { fg = p.syntax.comment },
		WhichKeyIconPurple = { fg = p.diagnostic.hint },
		WhichKeyIconRed = { fg = p.diagnostic.error },
		WhichKeyIconYellow = { fg = p.diagnostic.warning },
		WhichKeySeparator = { fg = p.surface.muted },
		WhichKeyValue = { fg = p.text.muted },
	}
end

return M
