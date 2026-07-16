local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local neotheme = require("neotheme")
local themes = require("neotheme.themes")

local function assert_sorted_unique(values, label)
	local sorted = vim.deepcopy(values)
	table.sort(sorted)
	h.eq(sorted, values, label .. " are sorted")
	local seen = {}
	for _, value in ipairs(values) do
		h.falsy(seen[value], label .. " contain duplicate " .. value)
		seen[value] = true
	end
end

local families = neotheme.families()
h.truthy(#families > 0, "family registry is non-empty")
assert_sorted_unique(families, "family names")

local family_themes = {}
for _, family in ipairs(families) do
	local members = neotheme.themes(family)
	h.truthy(#members > 0, family .. " has themes")
	assert_sorted_unique(members, family .. " themes")
	for _, theme in ipairs(members) do
		h.falsy(family_themes[theme], "theme belongs to one family: " .. theme)
		family_themes[theme] = family
		h.eq(family, themes.family(theme), "theme family metadata: " .. theme)
	end
end

local built_ins = {}
for _, theme in ipairs(neotheme.themes()) do
	if theme ~= "custom" then
		table.insert(built_ins, theme)
	end
end
local grouped = vim.tbl_keys(family_themes)
table.sort(grouped)
h.eq(built_ins, grouped, "families partition every built-in theme")
h.eq(nil, themes.family("custom"), "custom has no built-in family")

local unknown_ok, unknown_error = pcall(neotheme.themes, "unknown-family")
h.falsy(unknown_ok, "unknown family is rejected")
h.truthy(tostring(unknown_error):find("unknown-family", 1, true), "unknown family error")

neotheme._register_commands()
neotheme._register_commands()
h.eq(2, vim.fn.exists(":NeothemeList"), "list command registration is idempotent")
h.eq(families, vim.fn.getcompletion("NeothemeList ", "cmdline"), "list completion uses families")

local grouped_lines = {}
for _, family in ipairs(families) do
	table.insert(grouped_lines, family)
	for _, theme in ipairs(neotheme.themes(family)) do
		table.insert(grouped_lines, "  " .. theme)
	end
end
h.eq(
	table.concat(grouped_lines, "\n"),
	vim.api.nvim_exec2("NeothemeList", { output = true }).output,
	"list command groups themes by family"
)

local selected_family = families[1]
h.eq(
	table.concat(neotheme.themes(selected_family), "\n"),
	vim.api.nvim_exec2("NeothemeList " .. selected_family, { output = true }).output,
	"list command filters one family"
)

local invalid_ok, invalid_error = pcall(vim.api.nvim_exec2, "NeothemeList unknown-family", {
	output = true,
})
h.falsy(invalid_ok, "list command rejects unknown families")
h.truthy(tostring(invalid_error):find("unknown-family", 1, true), "list unknown-family error")
local surplus_ok, surplus_error = pcall(vim.api.nvim_exec2, "NeothemeList one two", {
	output = true,
})
h.falsy(surplus_ok, "list command rejects surplus arguments")
h.truthy(
	tostring(surplus_error):find("at most one family argument", 1, true),
	"list argument error"
)
