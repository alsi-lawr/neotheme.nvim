local M = {}

---@param p NeothemePalette
---@return table<string, NeothemeHighlight>
function M.get(p)
	return {
		SagaNormal = { link = "NormalFloat" },
		SagaBorder = { link = "FloatBorder" },
		SagaTitle = { link = "FloatTitle" },
		SagaHeader = { fg = p.ui.accent, bold = true },
		SagaText = { fg = p.text.primary },
		SagaDetail = { fg = p.text.muted },
		SagaBeacon = { bg = p.ui.accent },
		SagaVirtLine = { fg = p.surface.muted },
		SagaSpinner = { fg = p.diagnostic.hint },
		SagaSpinnerTitle = { fg = p.diagnostic.information },
		SagaLightBulb = { fg = p.diagnostic.warning },
		SagaActionTitle = { fg = p.ui.accent, bold = true },
		SagaActionContent = { fg = p.text.primary },
		SagaRenamePromptPrefix = { fg = p.diagnostic.information },
		SagaRenameBorder = { link = "FloatBorder" },
		SagaRenameNormal = { link = "NormalFloat" },
		SagaFinderSelection = { link = "Visual" },
		SagaFinderFname = { fg = p.ui.directory },
		SagaFinderCount = { fg = p.syntax.literal },
		SagaFinderIcon = { fg = p.ui.accent },
		SagaCodeActionTitle = { fg = p.ui.accent, bold = true },
		SagaCodeActionContent = { fg = p.text.primary },
		SagaCodeActionBorder = { link = "FloatBorder" },
		SagaHoverNormal = { link = "NormalFloat" },
		SagaHoverBorder = { link = "FloatBorder" },
		SagaHoverTitle = { link = "FloatTitle" },
		SagaSignatureHelpNormal = { link = "NormalFloat" },
		SagaSignatureHelpBorder = { link = "FloatBorder" },
		SagaDiagnosticNormal = { link = "NormalFloat" },
		SagaDiagnosticBorder = { link = "FloatBorder" },
		SagaDiagnosticHeader = { fg = p.diagnostic.warning, bold = true },
		SagaDiagnosticSource = { fg = p.text.muted },
		SagaDiagnosticPos = { fg = p.syntax.literal },
		SagaDiagnosticWord = { fg = p.text.strong },
		SagaDiagnosticText = { fg = p.text.primary },
		SagaWinbarSep = { fg = p.surface.muted },
		SagaWinbarFileName = { fg = p.text.bright },
		SagaWinbarFileIcon = { fg = p.ui.directory },
		SagaWinbarFolderName = { fg = p.syntax.property },
	}
end

return M
