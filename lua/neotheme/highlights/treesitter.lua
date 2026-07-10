local M = {}

---@param options NeothemeOptions
---@param p NeothemePalette
---@return table<string, NeothemeHighlight>
function M.get(options, p)
	return {
		["@variable"] = { link = "Identifier" },
		["@variable.builtin"] = { fg = p.syntax.keyword },
		["@variable.parameter"] = { link = "NeothemeTextBright" },
		["@variable.parameter.builtin"] = { fg = p.syntax.keyword },
		["@variable.member"] = { link = "NeothemeProperty" },

		["@constant"] = { link = "Constant" },
		["@constant.builtin"] = { fg = p.syntax.literal, bold = options.bold },
		["@constant.macro"] = { link = "Macro" },

		["@module"] = { fg = p.syntax.function_name },
		["@module.builtin"] = { fg = p.syntax.function_name, bold = options.bold },
		["@label"] = { link = "Label" },

		["@string"] = { link = "String" },
		["@string.documentation"] = { link = "String" },
		["@string.regexp"] = { fg = p.syntax.regexp },
		["@string.escape"] = { fg = p.syntax.literal },
		["@string.special"] = { fg = p.syntax.string },
		["@string.special.symbol"] = { fg = p.syntax.literal },
		["@string.special.path"] = { fg = p.ui.directory },
		["@string.special.url"] = { fg = p.markup.link, underline = options.underline },

		["@character"] = { link = "Character" },
		["@character.special"] = { link = "SpecialChar" },
		["@boolean"] = { link = "Boolean" },
		["@number"] = { link = "Number" },
		["@number.float"] = { link = "Float" },

		["@type"] = { link = "Type" },
		["@type.builtin"] = { fg = p.syntax.type, bold = options.bold },
		["@type.definition"] = { fg = p.syntax.type, underline = options.underline },
		["@attribute"] = { fg = p.syntax.attribute },
		["@attribute.builtin"] = { fg = p.syntax.attribute, bold = options.bold },
		["@property"] = { link = "NeothemeProperty" },

		["@function"] = { link = "Function" },
		["@function.builtin"] = { fg = p.syntax.function_name, bold = options.bold },
		["@function.call"] = { link = "Function" },
		["@function.macro"] = { fg = p.syntax.literal },
		["@function.method"] = { link = "Function" },
		["@function.method.call"] = { link = "Function" },
		["@constructor"] = { fg = p.syntax.function_name },
		["@operator"] = { link = "Operator" },

		["@keyword"] = { link = "Keyword" },
		["@keyword.coroutine"] = { link = "Keyword" },
		["@keyword.function"] = { link = "Keyword" },
		["@keyword.operator"] = { link = "Operator" },
		["@keyword.import"] = { link = "Include" },
		["@keyword.type"] = { link = "Keyword" },
		["@keyword.modifier"] = { link = "StorageClass" },
		["@keyword.repeat"] = { link = "Repeat" },
		["@keyword.return"] = { link = "Keyword" },
		["@keyword.debug"] = { link = "Debug" },
		["@keyword.exception"] = { link = "Exception" },
		["@keyword.conditional"] = { link = "Conditional" },
		["@keyword.conditional.ternary"] = { link = "Conditional" },
		["@keyword.directive"] = { link = "PreProc" },
		["@keyword.directive.define"] = { link = "Define" },

		["@punctuation.delimiter"] = { link = "Delimiter" },
		["@punctuation.bracket"] = { link = "NeothemePunctuation" },
		["@punctuation.special"] = { link = "Special" },

		["@comment"] = { link = "Comment" },
		["@comment.documentation"] = { link = "Comment" },
		["@comment.error"] = { link = "DiagnosticError" },
		["@comment.warning"] = { link = "DiagnosticWarn" },
		["@comment.todo"] = { link = "Todo" },
		["@comment.note"] = { link = "DiagnosticInfo" },

		["@markup.strong"] = { fg = p.text.strong, bold = options.bold },
		["@markup.italic"] = { fg = p.text.primary, italic = true },
		["@markup.strikethrough"] = { fg = p.text.primary, strikethrough = true },
		["@markup.underline"] = { fg = p.text.primary, underline = options.underline },
		["@markup.heading"] = { fg = p.markup.heading_1, bold = options.bold },
		["@markup.heading.1"] = { fg = p.markup.heading_1, bold = options.bold },
		["@markup.heading.2"] = { fg = p.markup.heading_2, bold = options.bold },
		["@markup.heading.3"] = { fg = p.markup.heading_3, bold = options.bold },
		["@markup.heading.4"] = { fg = p.markup.heading_4, bold = options.bold },
		["@markup.heading.5"] = { fg = p.markup.heading_5, bold = options.bold },
		["@markup.heading.6"] = { fg = p.markup.heading_6, bold = options.bold },
		["@markup.quote"] = { fg = p.markup.quote, italic = true },
		["@markup.math"] = { fg = p.markup.math },
		["@markup.link"] = { fg = p.markup.link },
		["@markup.link.label"] = { fg = p.markup.link_label },
		["@markup.link.url"] = { fg = p.markup.link, underline = options.underline },
		["@markup.raw"] = { fg = p.markup.raw },
		["@markup.raw.block"] = { fg = p.markup.raw },
		["@markup.list"] = { fg = p.markup.list },
		["@markup.list.checked"] = { fg = p.markup.checked },
		["@markup.list.unchecked"] = { fg = p.markup.unchecked },

		["@diff.plus"] = { link = "Added" },
		["@diff.minus"] = { link = "Removed" },
		["@diff.delta"] = { link = "Changed" },

		["@tag"] = { link = "Tag" },
		["@tag.builtin"] = { fg = p.syntax.tag, bold = options.bold },
		["@tag.attribute"] = { fg = p.syntax.attribute },
		["@tag.delimiter"] = { link = "Delimiter" },
	}
end

return M
