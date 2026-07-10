local M = {}

local semantic_types = {
	class = "@type",
	comment = "@comment",
	decorator = "@attribute",
	enum = "@type",
	enumMember = "@constant",
	event = "@type",
	["function"] = "@function",
	interface = "@type",
	keyword = "@keyword",
	macro = "@constant.macro",
	method = "@function.method",
	modifier = "@keyword.modifier",
	namespace = "@module",
	number = "@number",
	operator = "@operator",
	parameter = "@variable.parameter",
	property = "@property",
	regexp = "@string.regexp",
	string = "@string",
	struct = "@type",
	type = "@type",
	typeParameter = "@type.definition",
	variable = "@variable",
}

---@param options NeothemeOptions
---@param p NeothemePalette
---@return table<string, NeothemeHighlight>
function M.get(options, p)
	local groups = {
		LspReferenceText = { bg = p.surface.selected },
		LspReferenceRead = { bg = p.surface.addition },
		LspReferenceWrite = { bg = p.surface.selected, underline = options.underline },
		LspReferenceTarget = { fg = p.text.on_accent, bg = p.ui.accent },
		LspInlayHint = { fg = p.text.muted, bg = p.surface.dark, italic = true },
		LspCodeLens = { fg = p.text.muted, italic = true },
		LspCodeLensSeparator = { fg = p.surface.muted },
		LspSignatureActiveParameter = { fg = p.ui.accent, bold = options.bold },

		DiagnosticDeprecated = { fg = p.text.muted, strikethrough = true },
		DiagnosticUnnecessary = {
			fg = p.text.muted,
			sp = p.text.muted,
			undercurl = options.undercurl,
		},

		["@lsp.mod.abstract"] = { italic = true },
		["@lsp.mod.async"] = { italic = true },
		["@lsp.mod.declaration"] = { underline = options.underline },
		["@lsp.mod.defaultLibrary"] = { bold = options.bold },
		["@lsp.mod.definition"] = { bold = options.bold },
		["@lsp.mod.deprecated"] = { strikethrough = true },
		["@lsp.mod.documentation"] = { italic = true },
		["@lsp.mod.modification"] = { underline = options.underline },
		["@lsp.mod.readonly"] = { sp = p.syntax.literal, underline = options.underline },
		["@lsp.mod.static"] = { bold = options.bold },

		["@lsp.typemod.variable.readonly"] = { link = "@constant" },
		["@lsp.typemod.parameter.readonly"] = { link = "@constant" },
		["@lsp.typemod.property.readonly"] = { link = "@constant" },
		["@lsp.typemod.enumMember.readonly"] = { link = "@constant" },
		["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
		["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
		["@lsp.typemod.method.defaultLibrary"] = { link = "@function.builtin" },
		["@lsp.typemod.type.defaultLibrary"] = { link = "@type.builtin" },
		["@lsp.typemod.class.defaultLibrary"] = { link = "@type.builtin" },
		["@lsp.typemod.namespace.defaultLibrary"] = { link = "@module.builtin" },
		["@lsp.typemod.decorator.defaultLibrary"] = { link = "@attribute.builtin" },
	}

	local severities = {
		Error = { color = p.diagnostic.error, base = "NeothemeError" },
		Warn = { color = p.diagnostic.warning, base = "NeothemeWarning" },
		Info = { color = p.diagnostic.information, base = "NeothemeInformation" },
		Hint = { color = p.diagnostic.hint, base = "NeothemeHint" },
		Ok = { color = p.diagnostic.success, base = "NeothemeSuccess" },
	}

	for severity, definition in pairs(severities) do
		groups["Diagnostic" .. severity] = { link = definition.base }
		groups["DiagnosticVirtualText" .. severity] = { link = definition.base }
		groups["DiagnosticVirtualLines" .. severity] = { link = definition.base }
		groups["DiagnosticUnderline" .. severity] = {
			sp = definition.color,
			undercurl = options.undercurl,
		}
		groups["DiagnosticFloating" .. severity] = { link = definition.base }
		groups["DiagnosticSign" .. severity] = { link = definition.base }
	end

	for token, capture in pairs(semantic_types) do
		groups["@lsp.type." .. token] = { link = capture }
	end

	return groups
end

return M
