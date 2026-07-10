local M = {}

---@param p NeothemePalette
---@return table<string, NeothemeHighlight>
function M.get(p)
	return {
		TelescopeNormal = { fg = p.text.primary, bg = p.surface.base },
		TelescopeBorder = { fg = p.surface.border, bg = p.surface.base },
		TelescopeTitle = { fg = p.ui.accent, bold = true },
		TelescopeSelection = { fg = p.text.strong, bg = p.surface.selected },
		TelescopeSelectionCaret = { fg = p.ui.accent, bg = p.surface.selected },
		TelescopeMultiSelection = { fg = p.diagnostic.hint, bg = p.surface.selected },
		TelescopeMatching = { fg = p.ui.search, bold = true },

		TelescopePromptNormal = { fg = p.text.primary, bg = p.surface.raised },
		TelescopePromptBorder = { fg = p.surface.border, bg = p.surface.raised },
		TelescopePromptTitle = { fg = p.text.on_accent, bg = p.ui.accent, bold = true },
		TelescopePromptPrefix = { fg = p.diagnostic.information },
		TelescopePromptCounter = { fg = p.text.muted },

		TelescopeResultsNormal = { fg = p.text.primary, bg = p.surface.base },
		TelescopeResultsBorder = { fg = p.surface.border, bg = p.surface.base },
		TelescopeResultsTitle = { fg = p.diagnostic.success, bold = true },
		TelescopeResultsClass = { link = "Type" },
		TelescopeResultsComment = { link = "Comment" },
		TelescopeResultsConstant = { link = "Constant" },
		TelescopeResultsField = { link = "@variable.member" },
		TelescopeResultsFunction = { link = "Function" },
		TelescopeResultsIdentifier = { link = "Identifier" },
		TelescopeResultsLineNr = { link = "LineNr" },
		TelescopeResultsMethod = { link = "@function.method" },
		TelescopeResultsOperator = { link = "Operator" },
		TelescopeResultsSpecialComment = { link = "SpecialComment" },
		TelescopeResultsStruct = { link = "Structure" },
		TelescopeResultsVariable = { link = "@variable" },
		TelescopeResultsDiffAdd = { link = "Added" },
		TelescopeResultsDiffChange = { link = "Changed" },
		TelescopeResultsDiffDelete = { link = "Removed" },

		TelescopePreviewNormal = { fg = p.text.primary, bg = p.surface.dark },
		TelescopePreviewBorder = { fg = p.surface.border, bg = p.surface.dark },
		TelescopePreviewTitle = { fg = p.text.on_accent, bg = p.diagnostic.information, bold = true },
		TelescopePreviewDirectory = { link = "Directory" },
		TelescopePreviewGroup = { fg = p.text.muted },
		TelescopePreviewCharDev = { fg = p.diagnostic.warning },
		TelescopePreviewBlock = { fg = p.diagnostic.warning },
		TelescopePreviewLink = { fg = p.diagnostic.information },
		TelescopePreviewMatch = { link = "Search" },
		TelescopePreviewLine = { link = "Visual" },
		TelescopePreviewMessage = { fg = p.text.muted },
		TelescopePreviewMessageFillchar = { fg = p.surface.muted },
		TelescopePreviewPipe = { fg = p.diagnostic.warning },
		TelescopePreviewSocket = { fg = p.diagnostic.hint },
		TelescopePreviewRead = { fg = p.diagnostic.success },
		TelescopePreviewWrite = { fg = p.diagnostic.warning },
		TelescopePreviewExecute = { fg = p.diagnostic.error },
		TelescopePreviewSticky = { fg = p.diagnostic.hint },
		TelescopePreviewHyphen = { fg = p.surface.muted },
		TelescopePreviewSize = { fg = p.syntax.literal },
		TelescopePreviewUser = { fg = p.diagnostic.information },
		TelescopePreviewDate = { fg = p.text.muted },
	}
end

return M
