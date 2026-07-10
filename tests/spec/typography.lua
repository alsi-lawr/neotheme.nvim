local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")

local representatives = {
	bold = { group = "NeothemeKeyword", attribute = "bold" },
	comments = { group = "NeothemeComment", attribute = "italic" },
	strings = { group = "NeothemeString", attribute = "italic" },
	folds = { group = "Folded", attribute = "italic" },
	operators = { group = "NeothemeOperator", attribute = "italic" },
	underline = { group = "Underlined", attribute = "underline" },
	undercurl = { group = "DiagnosticUnderlineError", attribute = "undercurl" },
}

local function snapshot()
	local result = {}
	for name, definition in pairs(representatives) do
		local highlight = h.highlight(definition.group)
		result[name] = {
			attribute = highlight[definition.attribute] == true,
			fg = highlight.fg,
			bg = highlight.bg,
			sp = highlight.sp,
		}
	end
	return result
end

h.load()
local baseline = snapshot()
h.eq(true, baseline.bold.attribute, "default bold")
h.eq(true, baseline.comments.attribute, "default comment italics")
h.eq(true, baseline.strings.attribute, "default string italics")
h.eq(true, baseline.folds.attribute, "default fold italics")
h.eq(false, baseline.operators.attribute, "default operator italics")
h.eq(true, baseline.underline.attribute, "default underline")
h.eq(true, baseline.undercurl.attribute, "default undercurl")

local cases = {
	bold = { bold = false },
	comments = { italic = { comments = false } },
	strings = { italic = { strings = false } },
	folds = { italic = { folds = false } },
	operators = { italic = { operators = true } },
	underline = { underline = false },
	undercurl = { undercurl = false },
}

for changed, options in pairs(cases) do
	h.load(options)
	local actual = snapshot()

	for name, definition in pairs(actual) do
		local expected_attribute = baseline[name].attribute
		if name == changed then
			expected_attribute = not expected_attribute
		end
		h.eq(expected_attribute, definition.attribute, changed .. " must not alter " .. name)
		h.eq(
			baseline[name].fg,
			definition.fg,
			changed .. " must not alter " .. name .. " foreground"
		)
		h.eq(
			baseline[name].bg,
			definition.bg,
			changed .. " must not alter " .. name .. " background"
		)
		h.eq(
			baseline[name].sp,
			definition.sp,
			changed .. " must not alter " .. name .. " special color"
		)
	end
end
