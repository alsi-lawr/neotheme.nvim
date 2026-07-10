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
		CmpItemAbbr = { link = "Pmenu" },
		CmpItemAbbrDeprecated = { link = "DiagnosticDeprecated" },
		CmpItemAbbrMatch = { link = "PmenuMatch" },
		CmpItemAbbrMatchFuzzy = { link = "PmenuMatch" },
		CmpItemKind = { link = "PmenuKind" },
		CmpItemKindIcon = { link = "PmenuKind" },
		CmpItemMenu = { link = "PmenuExtra" },
	}

	for kind, target in pairs(kinds) do
		groups["CmpItemKind" .. kind] = { link = target }
		groups["CmpItemKind" .. kind .. "Icon"] = { link = target }
	end

	return groups
end

return M
