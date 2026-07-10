local M = {}

local kinds = {
	Text = "NeothemeTextBright",
	Method = "NeothemeFunction",
	Function = "NeothemeFunction",
	Constructor = "NeothemeFunction",
	Field = "NeothemeProperty",
	Variable = "Identifier",
	Class = "NeothemeType",
	Interface = "NeothemeType",
	Module = "NeothemeFunction",
	Property = "NeothemeProperty",
	Unit = "NeothemeNumber",
	Value = "NeothemeNumber",
	Enum = "NeothemeType",
	Keyword = "NeothemeKeyword",
	Snippet = "NeothemeNumber",
	Color = "NeothemeKeyword",
	File = "NeothemeTextBright",
	Reference = "NeothemeNumber",
	Folder = "Directory",
	EnumMember = "NeothemeNumber",
	Constant = "NeothemeNumber",
	Struct = "NeothemeType",
	Event = "NeothemeComment",
	Operator = "NeothemeOperator",
	TypeParameter = "NeothemeType",
}

---@return table<string, NeothemeHighlight>
function M.get()
	local groups = {
		BlinkCmpMenu = { link = "Pmenu" },
		BlinkCmpMenuBorder = { link = "PmenuBorder" },
		BlinkCmpMenuSelection = { link = "PmenuSel" },
		BlinkCmpScrollBarThumb = { link = "PmenuThumb" },
		BlinkCmpScrollBarGutter = { link = "PmenuSbar" },
		BlinkCmpLabel = { link = "Pmenu" },
		BlinkCmpLabelDeprecated = { link = "DiagnosticDeprecated" },
		BlinkCmpLabelMatch = { link = "PmenuMatch" },
		BlinkCmpLabelDetail = { link = "PmenuExtra" },
		BlinkCmpLabelDescription = { link = "PmenuExtra" },
		BlinkCmpKind = { link = "PmenuKind" },
		BlinkCmpSource = { link = "PmenuExtra" },
		BlinkCmpGhostText = { link = "ComplHint" },
		BlinkCmpDoc = { link = "NormalFloat" },
		BlinkCmpDocBorder = { link = "FloatBorder" },
		BlinkCmpDocSeparator = { link = "WinSeparator" },
		BlinkCmpDocCursorLine = { link = "Visual" },
		BlinkCmpSignatureHelp = { link = "NormalFloat" },
		BlinkCmpSignatureHelpBorder = { link = "FloatBorder" },
		BlinkCmpSignatureHelpActiveParameter = { link = "LspSignatureActiveParameter" },
	}

	for kind, target in pairs(kinds) do
		groups["BlinkCmpKind" .. kind] = { link = target }
	end

	return groups
end

return M
