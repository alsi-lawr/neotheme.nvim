local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")

local representatives = {
	bold = { group = "NeothemeKeyword", attribute = "bold", default = true },
	comments = { group = "NeothemeComment", attribute = "italic", default = true },
	strings = { group = "NeothemeString", attribute = "italic", default = true },
	folds = { group = "Folded", attribute = "italic", default = true },
	operators = { group = "NeothemeOperator", attribute = "italic", default = false },
	underline = { group = "Underlined", attribute = "underline", default = true },
	undercurl = { group = "DiagnosticUnderlineError", attribute = "undercurl", default = true },
}

h.load()
local baseline_colors = {}
for name, definition in pairs(representatives) do
	local highlight = h.highlight(definition.group)
	h.eq(
		definition.default,
		highlight[definition.attribute] == true,
		"default typography: " .. name
	)
	baseline_colors[name] = { fg = highlight.fg, bg = highlight.bg, sp = highlight.sp }
end

h.load({
	bold = false,
	italic = {
		comments = false,
		strings = false,
		folds = false,
		operators = true,
	},
	underline = false,
	undercurl = false,
})
for name, definition in pairs(representatives) do
	local highlight = h.highlight(definition.group)
	h.eq(
		not definition.default,
		highlight[definition.attribute] == true,
		"configured typography: " .. name
	)
	h.eq(
		baseline_colors[name],
		{ fg = highlight.fg, bg = highlight.bg, sp = highlight.sp },
		"typography options preserve colors: " .. name
	)
end
