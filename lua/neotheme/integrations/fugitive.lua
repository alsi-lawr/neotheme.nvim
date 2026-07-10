local M = {}

---@return table<string, NeothemeHighlight>
function M.get()
	return {
		fugitiveHeader = { link = "Title" },
		fugitiveHeading = { link = "Title" },
		fugitiveStagedHeading = { link = "Added" },
		fugitiveUnstagedHeading = { link = "Changed" },
		fugitiveUntrackedHeading = { link = "DiagnosticHint" },
		fugitiveHash = { link = "Constant" },
		fugitiveSymbolicRef = { link = "Function" },
		fugitiveHelpTag = { link = "Tag" },
		fugitiveHelpHeader = { link = "Title" },
		fugitiveCount = { link = "Number" },
		fugitiveModifier = { link = "Type" },
		fugitiveHunk = { link = "Changed" },
		fugitiveStagedModifier = { link = "Added" },
		fugitiveUnstagedModifier = { link = "Changed" },
		fugitiveUntrackedModifier = { link = "DiagnosticHint" },
		fugitiveStagedSection = { link = "Added" },
		fugitiveUnstagedSection = { link = "Changed" },
		fugitiveUntrackedSection = { link = "DiagnosticHint" },
	}
end

return M
