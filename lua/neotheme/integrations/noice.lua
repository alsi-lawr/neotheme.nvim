local M = {}

local cmdline_variants = {
	"Calculator",
	"Cmdline",
	"Filter",
	"Help",
	"IncRename",
	"Input",
	"Lua",
}

local completion_kinds = {
	"Class",
	"Color",
	"Constant",
	"Constructor",
	"Enum",
	"EnumMember",
	"Field",
	"File",
	"Folder",
	"Function",
	"Interface",
	"Keyword",
	"Method",
	"Module",
	"Property",
	"Snippet",
	"Struct",
	"Text",
	"Unit",
	"Value",
	"Variable",
}

---@return table<string, NeothemeHighlight>
function M.get()
	local groups = {
		NoiceCmdline = { link = "MsgArea" },
		NoiceCmdlineIcon = { link = "DiagnosticSignInfo" },
		NoiceCmdlineIconSearch = { link = "DiagnosticSignWarn" },
		NoiceCmdlinePopup = { link = "NormalFloat" },
		NoiceCmdlinePopupBorder = { link = "DiagnosticSignInfo" },
		NoiceCmdlinePopupBorderSearch = { link = "DiagnosticSignWarn" },
		NoiceCmdlinePopupTitle = { link = "DiagnosticSignInfo" },
		NoiceCmdlinePrompt = { link = "Title" },
		NoiceCompletionItemKindDefault = { link = "Special" },
		NoiceCompletionItemMenu = { link = "PmenuExtra" },
		NoiceCompletionItemWord = { link = "Pmenu" },
		NoiceConfirm = { link = "NormalFloat" },
		NoiceConfirmBorder = { link = "DiagnosticSignInfo" },
		NoiceCursor = { link = "Cursor" },
		NoiceFormatConfirm = { link = "CursorLine" },
		NoiceFormatConfirmDefault = { link = "Visual" },
		NoiceFormatDate = { link = "Special" },
		NoiceFormatEvent = { link = "NonText" },
		NoiceFormatKind = { link = "NonText" },
		NoiceFormatLevelDebug = { link = "NonText" },
		NoiceFormatLevelError = { link = "DiagnosticVirtualTextError" },
		NoiceFormatLevelInfo = { link = "DiagnosticVirtualTextInfo" },
		NoiceFormatLevelOff = { link = "NonText" },
		NoiceFormatLevelTrace = { link = "NonText" },
		NoiceFormatLevelWarn = { link = "DiagnosticVirtualTextWarn" },
		NoiceFormatProgressDone = { link = "Search" },
		NoiceFormatProgressTodo = { link = "CursorLine" },
		NoiceFormatTitle = { link = "Title" },
		NoiceLspProgressClient = { link = "Title" },
		NoiceLspProgressSpinner = { link = "Constant" },
		NoiceLspProgressTitle = { link = "NonText" },
		NoiceMini = { link = "MsgArea" },
		NoicePopup = { link = "NormalFloat" },
		NoicePopupBorder = { link = "FloatBorder" },
		NoicePopupmenu = { link = "Pmenu" },
		NoicePopupmenuBorder = { link = "PmenuBorder" },
		NoicePopupmenuMatch = { link = "PmenuMatch" },
		NoicePopupmenuSelected = { link = "PmenuSel" },
		NoiceScrollbar = { link = "PmenuSbar" },
		NoiceScrollbarThumb = { link = "PmenuThumb" },
		NoiceSplit = { link = "NormalFloat" },
		NoiceSplitBorder = { link = "FloatBorder" },
		NoiceVirtualText = { link = "DiagnosticVirtualTextInfo" },
	}

	for _, variant in ipairs(cmdline_variants) do
		groups["NoiceCmdlineIcon" .. variant] = { link = "NoiceCmdlineIcon" }
		groups["NoiceCmdlinePopupBorder" .. variant] = { link = "NoiceCmdlinePopupBorder" }
	end

	for _, kind in ipairs(completion_kinds) do
		groups["NoiceCompletionItemKind" .. kind] = { link = "NoiceCompletionItemKindDefault" }
	end

	return groups
end

return M
