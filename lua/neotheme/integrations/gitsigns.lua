local M = {}

---@param p NeothemePalette
---@return table<string, NeothemeHighlight>
function M.get(p)
	local signs = {
		Add = { color = p.version_control.added, line = "DiffAdd" },
		Change = { color = p.version_control.changed, line = "DiffChange" },
		Delete = { color = p.version_control.removed, line = "DiffDelete" },
		Topdelete = { color = p.version_control.removed, line = "DiffDelete" },
		Changedelete = { color = p.version_control.conflict, line = "DiffChange" },
		Untracked = { color = p.version_control.added, line = "DiffAdd" },
	}
	local groups = {
		GitSignsAddPreview = { link = "DiffAdd" },
		GitSignsDeletePreview = { link = "DiffDelete" },
		GitSignsAddInline = { fg = p.version_control.added, bg = p.surface.addition },
		GitSignsDeleteInline = { fg = p.version_control.removed, bg = p.surface.selected },
		GitSignsChangeInline = { fg = p.version_control.changed, bg = p.surface.selected },
		GitSignsAddLnInline = { link = "GitSignsAddInline" },
		GitSignsChangeLnInline = { link = "GitSignsChangeInline" },
		GitSignsDeleteLnInline = { link = "GitSignsDeleteInline" },
		GitSignsDeleteVirtLn = { link = "DiffDelete" },
		GitSignsDeleteVirtLnInLine = { link = "GitSignsDeleteLnInline" },
		GitSignsVirtLnum = { fg = p.text.muted, bg = p.surface.raised },
		GitSignsCurrentLineBlame = { fg = p.text.muted, italic = true },
	}

	for name, definition in pairs(signs) do
		groups["GitSigns" .. name] = { fg = definition.color }
		groups["GitSigns" .. name .. "Nr"] = { fg = definition.color }
		groups["GitSigns" .. name .. "Ln"] = { link = definition.line }
		groups["GitSigns" .. name .. "Cul"] = { fg = definition.color, bg = p.surface.raised }
		groups["GitSignsStaged" .. name] = { fg = definition.color }
		groups["GitSignsStaged" .. name .. "Nr"] = { fg = definition.color }
		groups["GitSignsStaged" .. name .. "Ln"] = { link = definition.line }
		groups["GitSignsStaged" .. name .. "Cul"] = { fg = definition.color, bg = p.surface.raised }
	end

	return groups
end

return M
