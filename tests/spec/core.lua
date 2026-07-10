local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local engine = require("neotheme")

local function assert_defined(definitions, names, label)
	for _, name in ipairs(names) do
		h.truthy(definitions[name], string.format("%s definition is missing: %s", label, name))
	end
end

h.load()

local options = require("neotheme.config").get()
local palette = engine.palette()

h.eq("neotheme", vim.g.colors_name, "colors_name")
h.eq("dark", vim.o.background, "background")
h.eq(true, vim.o.termguicolors, "termguicolors")

local runtime_groups = {
	Normal = { fg = palette.text.primary, bg = palette.surface.base },
	Cursor = { fg = palette.text.on_accent, bg = palette.ui.cursor },
	Search = { fg = palette.text.on_accent, bg = palette.ui.search },
	StatusLine = { fg = palette.text.strong, bg = palette.surface.selected },
}
for name, expected in pairs(runtime_groups) do
	local actual = h.highlight(name)
	h.eq(h.color(expected.fg), actual.fg, name .. " foreground")
	h.eq(h.color(expected.bg), actual.bg, name .. " background")
end

local core = require("neotheme.highlights.core").get(options, palette)
assert_defined(core, {
	"Normal",
	"Cursor",
	"DiffTextAdd",
	"TermCursor",
	"StderrMsg",
	"Folded",
	"CurSearch",
	"MsgSeparator",
	"FloatFooter",
	"PmenuMatch",
	"ComplHint",
	"SnippetTabstopActive",
	"StatusLineTerm",
	"TabLineSel",
	"WinBarNC",
	"NeothemeSidebar",
	"qfWarning",
}, "Neovim 0.12 UI")

assert_defined(core, {
	"Comment",
	"String",
	"Number",
	"Function",
	"Keyword",
	"Operator",
	"Type",
	"Added",
	"Changed",
	"Removed",
}, "syntax")

local treesitter = require("neotheme.highlights.treesitter").get(options, palette)
assert_defined(treesitter, {
	"@variable.member",
	"@function.method",
	"@function.method.call",
	"@keyword.conditional",
	"@keyword.directive.define",
	"@markup.heading.6",
	"@markup.link.url",
	"@markup.list.checked",
	"@diff.plus",
	"@diff.minus",
	"@diff.delta",
}, "Neovim 0.12 Tree-sitter")

for _, name in ipairs({
	"@method",
	"@parameter",
	"@conditional",
	"@repeat",
	"@storageclass",
	"@field",
	"@text.strong",
	"@text.diff.add",
}) do
	h.eq(nil, treesitter[name], "obsolete Tree-sitter capture: " .. name)
end

h.eq("Function", h.highlight("@function.method", true).link, "runtime method capture")
h.eq(h.color(palette.markup.heading_1), h.highlight("@markup.heading").fg, "runtime markup capture")
h.eq("Added", h.highlight("@diff.plus", true).link, "runtime diff capture")

local lsp = require("neotheme.highlights.lsp").get(options, palette)
assert_defined(lsp, {
	"LspReferenceText",
	"LspReferenceWrite",
	"LspInlayHint",
	"LspCodeLens",
	"LspSignatureActiveParameter",
}, "LSP UI")

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
for token, target in pairs(semantic_types) do
	h.eq(target, lsp["@lsp.type." .. token].link, "semantic token: " .. token)
end

h.eq(true, lsp["@lsp.mod.deprecated"].strikethrough, "deprecated semantic modifier")
h.eq("@constant", lsp["@lsp.typemod.variable.readonly"].link, "readonly semantic modifier")
h.eq("@function.builtin", lsp["@lsp.typemod.function.defaultLibrary"].link, "default-library modifier")

for _, severity in ipairs({ "Error", "Warn", "Info", "Hint", "Ok" }) do
	for _, kind in ipairs({ "", "VirtualText", "VirtualLines", "Underline", "Floating", "Sign" }) do
		h.truthy(lsp["Diagnostic" .. kind .. severity], "diagnostic definition is missing")
	end
end
h.eq(h.color(palette.diagnostic.information), h.highlight("DiagnosticInfo").fg, "information diagnostic")

local terminal = {
	[0] = palette.surface.raised,
	[1] = palette.version_control.conflict,
	[2] = palette.diagnostic.success,
	[8] = palette.surface.raised,
	[15] = palette.text.on_error,
}
for index, color in pairs(terminal) do
	h.eq(color, vim.g["terminal_color_" .. index], "terminal color " .. index)
end
h.eq(palette.surface.raised, vim.g.terminal_color_background, "terminal background")
h.eq(palette.text.primary, vim.g.terminal_color_foreground, "terminal foreground")
