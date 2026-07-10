local M = {}

---@param p NeothemePalette
---@return table<string, NeothemeHighlight>
function M.get(p)
	local groups = {
		BufferLineFill = { fg = p.surface.muted, bg = p.surface.dark },
		BufferLineBackground = { fg = p.text.muted, bg = p.surface.dark },
		BufferLineBufferVisible = { fg = p.text.primary, bg = p.surface.raised },
		BufferLineBufferSelected = { fg = p.text.strong, bg = p.surface.base, bold = true },
		BufferLineTab = { fg = p.text.muted, bg = p.surface.dark },
		BufferLineTabSelected = { fg = p.ui.accent, bg = p.surface.base, bold = true },
		BufferLineTabSeparator = { fg = p.surface.dark, bg = p.surface.dark },
		BufferLineTabSeparatorSelected = { fg = p.surface.dark, bg = p.surface.base },
		BufferLineTabClose = { fg = p.diagnostic.error, bg = p.surface.dark },
		BufferLineOffsetSeparator = { fg = p.surface.border, bg = p.surface.dark },
		BufferLineTruncMarker = { fg = p.text.muted, bg = p.surface.dark },
		BufferLineGroupLabel = { fg = p.text.on_accent, bg = p.ui.directory },
		BufferLineGroupSeparator = { fg = p.ui.directory, bg = p.surface.dark },
		BufferLineSeparator = { fg = p.surface.dark, bg = p.surface.dark },
		BufferLineSeparatorVisible = { fg = p.surface.dark, bg = p.surface.raised },
		BufferLineSeparatorSelected = { fg = p.surface.dark, bg = p.surface.base },
	}

	local variants = {
		CloseButton = p.diagnostic.error,
		Modified = p.version_control.changed,
		Duplicate = p.text.muted,
		Indicator = p.ui.accent,
		Pick = p.diagnostic.hint,
		Numbers = p.text.muted,
		Diagnostic = p.text.muted,
		Hint = p.diagnostic.hint,
		HintDiagnostic = p.diagnostic.hint,
		Info = p.diagnostic.information,
		InfoDiagnostic = p.diagnostic.information,
		Warning = p.diagnostic.warning,
		WarningDiagnostic = p.diagnostic.warning,
		Error = p.diagnostic.error,
		ErrorDiagnostic = p.diagnostic.error,
	}

	for name, color in pairs(variants) do
		groups["BufferLine" .. name] = { fg = color, bg = p.surface.dark }
		groups["BufferLine" .. name .. "Visible"] = { fg = color, bg = p.surface.raised }
		groups["BufferLine" .. name .. "Selected"] =
			{ fg = color, bg = p.surface.base, bold = true }
	end

	return groups
end

return M
