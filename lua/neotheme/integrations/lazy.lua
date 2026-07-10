local M = {}

---@return table<string, NeothemeHighlight>
function M.get()
	return {
		LazyBold = { link = "NeothemeTextStrong" },
		LazyButton = { link = "CursorLine" },
		LazyButtonActive = { link = "Visual" },
		LazyComment = { link = "Comment" },
		LazyCommit = { link = "@variable.builtin" },
		LazyCommitIssue = { link = "Number" },
		LazyCommitScope = { italic = true },
		LazyCommitType = { link = "Title" },
		LazyDimmed = { link = "Conceal" },
		LazyDir = { link = "@markup.link" },
		LazyError = { link = "DiagnosticError" },
		LazyH1 = { link = "IncSearch" },
		LazyH2 = { link = "NeothemeTextStrong" },
		LazyInfo = { link = "DiagnosticInfo" },
		LazyItalic = { italic = true },
		LazyLocal = { link = "Constant" },
		LazyNoCond = { link = "DiagnosticWarn" },
		LazyNormal = { link = "NormalFloat" },
		LazyProgressDone = { link = "Constant" },
		LazyProgressTodo = { link = "LineNr" },
		LazyProp = { link = "Conceal" },
		LazyReasonCmd = { link = "Operator" },
		LazyReasonEvent = { link = "Constant" },
		LazyReasonFt = { link = "Character" },
		LazyReasonImport = { link = "Identifier" },
		LazyReasonKeys = { link = "Statement" },
		LazyReasonPlugin = { link = "Special" },
		LazyReasonRequire = { link = "@variable.parameter" },
		LazyReasonRuntime = { link = "Macro" },
		LazyReasonSource = { link = "Character" },
		LazyReasonStart = { link = "@variable.member" },
		LazySpecial = { link = "@punctuation.special" },
		LazyTaskOutput = { link = "MsgArea" },
		LazyUrl = { link = "@markup.link.url" },
		LazyValue = { link = "String" },
		LazyWarning = { link = "DiagnosticWarn" },
	}
end

return M
