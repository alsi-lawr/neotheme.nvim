local M = {}

---@param p NeothemePalette
---@return table<string, NeothemeHighlight>
function M.get(p)
	return {
		NvimTreeNormal = { fg = p.text.primary, bg = p.surface.base },
		NvimTreeNormalFloat = { link = "NormalFloat" },
		NvimTreeNormalNC = { fg = p.text.primary, bg = p.surface.base },
		NvimTreeLineNr = { link = "LineNr" },
		NvimTreeWinSeparator = { fg = p.surface.border, bg = p.surface.base },
		NvimTreeEndOfBuffer = { fg = p.surface.base, bg = p.surface.base },
		NvimTreePopup = { link = "NormalFloat" },
		NvimTreeSignColumn = { fg = p.surface.muted, bg = p.surface.base },
		NvimTreeCursorColumn = { bg = p.surface.raised },
		NvimTreeCursorLine = { bg = p.surface.raised },
		NvimTreeCursorLineNr = { link = "CursorLineNr" },
		NvimTreeStatusLine = { link = "StatusLine" },
		NvimTreeStatusLineNC = { link = "StatusLineNC" },

		NvimTreeExecFile = { fg = p.diagnostic.success, bold = true },
		NvimTreeImageFile = { fg = p.syntax.literal },
		NvimTreeSpecialFile = { fg = p.ui.accent, underline = true },
		NvimTreeSymlink = { fg = p.text.muted, italic = true },

		NvimTreeRootFolder = { fg = p.ui.directory, bold = true },
		NvimTreeFolderName = { fg = p.ui.directory },
		NvimTreeEmptyFolderName = { fg = p.syntax.property },
		NvimTreeOpenedFolderName = { fg = p.ui.directory, bold = true },
		NvimTreeSymlinkFolderName = { fg = p.text.muted, italic = true },

		NvimTreeFileIcon = { fg = p.text.primary },
		NvimTreeSymlinkIcon = { fg = p.text.muted },
		NvimTreeFolderIcon = { fg = p.ui.directory },
		NvimTreeOpenedFolderIcon = { fg = p.ui.directory },
		NvimTreeClosedFolderIcon = { fg = p.ui.directory },
		NvimTreeFolderArrowClosed = { fg = p.text.muted },
		NvimTreeFolderArrowOpen = { fg = p.text.muted },
		NvimTreeIndentMarker = { fg = p.surface.border },

		NvimTreeWindowPicker = { fg = p.text.on_accent, bg = p.ui.accent, bold = true },
		NvimTreeLiveFilterPrefix = { fg = p.ui.accent, bold = true },
		NvimTreeLiveFilterValue = { fg = p.text.bright },

		NvimTreeCopiedHL = { fg = p.diagnostic.success },
		NvimTreeCutHL = { fg = p.diagnostic.error },
		NvimTreeBookmarkIcon = { fg = p.diagnostic.hint },
		NvimTreeBookmarkHL = { fg = p.diagnostic.hint },

		NvimTreeModifiedIcon = { fg = p.version_control.changed },
		NvimTreeModifiedFileHL = { fg = p.version_control.changed },
		NvimTreeModifiedFolderHL = { fg = p.version_control.changed },
		NvimTreeHiddenIcon = { fg = p.version_control.ignored },
		NvimTreeHiddenFileHL = { fg = p.version_control.ignored },
		NvimTreeHiddenFolderHL = { fg = p.version_control.ignored },
		NvimTreeHiddenDisplay = { fg = p.text.muted, italic = true },
		NvimTreeOpenedHL = { fg = p.text.strong, bold = true },

		NvimTreeGitDeletedIcon = { fg = p.version_control.removed },
		NvimTreeGitDirtyIcon = { fg = p.version_control.changed },
		NvimTreeGitIgnoredIcon = { fg = p.version_control.ignored },
		NvimTreeGitMergeIcon = { fg = p.version_control.conflict },
		NvimTreeGitNewIcon = { fg = p.version_control.added },
		NvimTreeGitRenamedIcon = { fg = p.diagnostic.hint },
		NvimTreeGitStagedIcon = { fg = p.version_control.added },

		NvimTreeGitFileDeletedHL = { link = "NvimTreeGitDeletedIcon" },
		NvimTreeGitFileDirtyHL = { link = "NvimTreeGitDirtyIcon" },
		NvimTreeGitFileIgnoredHL = { link = "NvimTreeGitIgnoredIcon" },
		NvimTreeGitFileMergeHL = { link = "NvimTreeGitMergeIcon" },
		NvimTreeGitFileNewHL = { link = "NvimTreeGitNewIcon" },
		NvimTreeGitFileRenamedHL = { link = "NvimTreeGitRenamedIcon" },
		NvimTreeGitFileStagedHL = { link = "NvimTreeGitStagedIcon" },

		NvimTreeGitFolderDeletedHL = { link = "NvimTreeGitFileDeletedHL" },
		NvimTreeGitFolderDirtyHL = { link = "NvimTreeGitFileDirtyHL" },
		NvimTreeGitFolderIgnoredHL = { link = "NvimTreeGitFileIgnoredHL" },
		NvimTreeGitFolderMergeHL = { link = "NvimTreeGitFileMergeHL" },
		NvimTreeGitFolderNewHL = { link = "NvimTreeGitFileNewHL" },
		NvimTreeGitFolderRenamedHL = { link = "NvimTreeGitFileRenamedHL" },
		NvimTreeGitFolderStagedHL = { link = "NvimTreeGitFileStagedHL" },

		NvimTreeDiagnosticErrorIcon = { link = "DiagnosticError" },
		NvimTreeDiagnosticWarnIcon = { link = "DiagnosticWarn" },
		NvimTreeDiagnosticInfoIcon = { link = "DiagnosticInfo" },
		NvimTreeDiagnosticHintIcon = { link = "DiagnosticHint" },
		NvimTreeDiagnosticErrorFileHL = { link = "DiagnosticUnderlineError" },
		NvimTreeDiagnosticWarnFileHL = { link = "DiagnosticUnderlineWarn" },
		NvimTreeDiagnosticInfoFileHL = { link = "DiagnosticUnderlineInfo" },
		NvimTreeDiagnosticHintFileHL = { link = "DiagnosticUnderlineHint" },
		NvimTreeDiagnosticErrorFolderHL = { link = "NvimTreeDiagnosticErrorFileHL" },
		NvimTreeDiagnosticWarnFolderHL = { link = "NvimTreeDiagnosticWarnFileHL" },
		NvimTreeDiagnosticInfoFolderHL = { link = "NvimTreeDiagnosticInfoFileHL" },
		NvimTreeDiagnosticHintFolderHL = { link = "NvimTreeDiagnosticHintFileHL" },
	}
end

return M
