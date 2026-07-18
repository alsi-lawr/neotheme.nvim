local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local editor = require("neotheme.palette_editor")
local palette = require("neotheme.palette")
local simplified = require("neotheme.themes.simplified")
local state = require("neotheme.state")
local themes = require("neotheme.themes")

vim.o.columns = 140
vim.o.lines = 40

local function copy(value)
	return vim.deepcopy(value)
end

local function press(key)
	vim.api.nvim_feedkeys(vim.keycode(key), "x", false)
end

local function write_record(family, name, record)
	local directory = vim.fs.joinpath(state.root(), "palettes", family)
	vim.fn.mkdir(directory, "p")
	vim.fn.writefile({ vim.json.encode(record) }, vim.fs.joinpath(directory, name .. ".json"))
end

local function record_path(family, name)
	return vim.fs.joinpath(state.root(), "palettes", family, name .. ".json")
end

local function read_record(family, name)
	return vim.json.decode(table.concat(vim.fn.readfile(record_path(family, name)), "\n"))
end

local function sorted_keys(value)
	local result = vim.tbl_keys(value)
	table.sort(result)
	return result
end

local simplified_categories = simplified.categories()
h.eq(4, #simplified_categories, "simplified source has four editor categories")
h.eq(9, #simplified_categories[1].fields, "simplified Surface has nine fields")
h.eq(6, #simplified_categories[2].fields, "simplified Text has six fields")
h.eq(7, #simplified_categories[3].fields, "simplified Syntax has seven fields")
h.eq(2, #simplified_categories[4].fields, "simplified Signals has two fields")

local neutral_simplified = require("neotheme.neutral_simplified_palette")
local simplified_dark = neutral_simplified.get("dark")
local simplified_light = neutral_simplified.get("light")
h.truthy(
	simplified.is_complete(simplified_dark),
	"dark simplified neutral source is strict-complete"
)
h.truthy(
	simplified.is_complete(simplified_light),
	"light simplified neutral source is strict-complete"
)
h.falsy(
	vim.deep_equal(simplified_dark, simplified_light),
	"simplified dark and light sources differ"
)
local fresh_simplified_dark = neutral_simplified.get("dark")
simplified_dark.surface_base = "#010203"
h.eq(
	fresh_simplified_dark.surface_base,
	neutral_simplified.get("dark").surface_base,
	"simplified neutral templates return fresh sources"
)
simplified_dark = fresh_simplified_dark

local expanded = simplified.transform(simplified_dark)
local expanded_again = simplified.transform(simplified_dark)
h.truthy(palette.is_complete(expanded), "simplified source expands to all 59 semantic roles")
h.eq(simplified_dark.surface_base, expanded.surface.base, "surface source expands directly")
h.eq(simplified_dark.text_muted, expanded.text.muted, "required muted text expands directly")
h.eq(
	simplified_dark.text_on_accent,
	expanded.text.on_accent,
	"required accent foreground expands directly"
)
h.eq(simplified_dark.syntax_keyword, expanded.syntax.operator, "keyword fans out to operator")
h.eq(simplified_dark.syntax_keyword, expanded.diagnostic.warning, "keyword fans out to warning")
h.eq(
	simplified_dark.syntax_function_name,
	expanded.markup.heading_2,
	"function color fans out to markup heading"
)
h.eq(
	simplified_dark.version_control_conflict,
	expanded.version_control.conflict,
	"conflict source expands directly"
)
h.eq(simplified_dark.text_on_error, expanded.ui.current_search, "error text fans out to search")
expanded.ui.accent = "#010203"
h.eq(
	simplified_dark.syntax_keyword,
	expanded_again.ui.accent,
	"expanded palettes do not share derived tables"
)
h.eq(
	simplified_dark.syntax_keyword,
	simplified.transform(simplified_dark).ui.accent,
	"expanded palette mutation cannot alter the source"
)

local full_dark = require("neotheme.neutral_palette").get("dark")
local full_light = require("neotheme.neutral_palette").get("light")
h.truthy(palette.is_complete(full_dark), "dark full neutral source remains complete")
h.truthy(palette.is_complete(full_light), "light full neutral source remains complete")
full_dark.surface.base = "#010203"
h.eq(
	"#1c1c1c",
	require("neotheme.neutral_palette").get("dark").surface.base,
	"full neutral template remains mutation-safe"
)

for _, family in ipairs({ "modes", "target", "empty-mode" }) do
	themes.create_family(family)
end
require("neotheme.commands").register()

local simple_record = themes.create_snapshot({
	background = "dark",
	mode = "simplified",
	palette = simplified_dark,
}, "modes", "simple-source")
local full_record = themes.create_snapshot({
	background = "dark",
	mode = "full",
	palette = require("neotheme.neutral_palette").get("dark"),
}, "modes", "full-source")
h.eq(2, simple_record.version, "simplified creation writes schema v2")
h.eq("simplified", simple_record.mode, "simplified source mode is retained")
h.eq(2, full_record.version, "full creation writes schema v2")
h.eq("full", full_record.mode, "full source mode is retained")
h.eq(
	{ "background", "family", "mode", "name", "palette", "version" },
	sorted_keys(read_record("modes", "simple-source")),
	"simplified persisted record has the exact v2 shape"
)
h.eq(
	{ "background", "family", "mode", "name", "palette", "version" },
	sorted_keys(read_record("modes", "full-source")),
	"full persisted record has the exact v2 shape"
)
h.eq(simplified_dark, read_record("modes", "simple-source").palette, "v2 stores compact source")
h.eq(
	require("neotheme.neutral_palette").get("dark"),
	read_record("modes", "full-source").palette,
	"v2 full mode stores expanded source"
)
local persisted_simple_source = copy(read_record("modes", "simple-source").palette)
simple_record.palette.surface_base = "#010203"
h.eq(
	persisted_simple_source,
	state.load().themes["simple-source"].palette,
	"returned simplified record cannot mutate persisted source"
)
simple_record = assert(state.load().themes["simple-source"])

local lookup_one = themes.get("simple-source")
local lookup_two = themes.get("simple-source")
lookup_one.surface.base = "#010203"
h.eq(simplified_dark.surface_base, lookup_two.surface.base, "registry returns fresh expansions")
h.eq(
	simplified_dark.surface_base,
	themes.get("simple-source").surface.base,
	"registry expansion mutation cannot alter persisted source"
)
require("neotheme").switch("simple-source")
h.eq(themes.get("simple-source"), require("neotheme").palette(), "runtime switch uses expansion")
h.eq(
	simplified_dark.surface_base,
	vim.g.terminal_color_background,
	"terminal highlights receive expanded simplified surface"
)

local simple_clone = themes.clone("simple-source", "target", "simple-clone")
local full_clone = themes.clone("full-source", "target", "full-clone")
local bundled_clone = themes.clone("gruber-dark", "target", "bundled-clone")
h.eq("simplified", simple_clone.mode, "user simplified clone preserves mode")
h.eq(simple_record.palette, simple_clone.palette, "user simplified clone preserves source")
h.eq("full", full_clone.mode, "user full clone preserves mode")
h.eq(full_record.palette, full_clone.palette, "user full clone preserves source")
h.eq("full", bundled_clone.mode, "bundled clone is full")
h.eq(themes.get("gruber-dark"), bundled_clone.palette, "bundled clone stores expanded palette")

local legacy_palette = themes.get("typeset-paper")
write_record("target", "legacy-v1", {
	version = 1,
	family = "target",
	name = "legacy-v1",
	background = "light",
	palette = legacy_palette,
})
local legacy = assert(state.load().themes["legacy-v1"])
h.eq(1, legacy.version, "strict v1 record retains its source version in memory")
h.eq("full", legacy.mode, "strict v1 record normalizes to full mode in memory")
h.eq(legacy_palette, themes.get("legacy-v1"), "v1 registry lookup has no expanded drift")
local forbidden_v1_simplified = {
	version = 1,
	family = "target",
	name = "forbidden-v1-simplified",
	background = "dark",
	mode = "simplified",
	palette = simplified_dark,
}
local forbidden_valid, forbidden_error = state.valid_theme(forbidden_v1_simplified)
h.falsy(forbidden_valid, "v1 simplified source is invalid at the validation boundary")
h.eq(
	"version 1 palette state must be mode-less or full",
	forbidden_error,
	"v1 simplified validation explains the compatibility boundary"
)
h.falsy(
	pcall(state.write_theme, forbidden_v1_simplified),
	"v1 simplified source is rejected at the write boundary"
)
h.falsy(
	vim.uv.fs_stat(record_path("target", "forbidden-v1-simplified")),
	"rejected v1 simplified source creates no bytes"
)
local legacy_clone = themes.clone("legacy-v1", "modes", "legacy-clone")
h.eq(2, legacy_clone.version, "v1 user clone writes v2")
h.eq("full", legacy_clone.mode, "v1 user clone preserves effective full mode")
h.eq(legacy_palette, legacy_clone.palette, "v1 user clone preserves authoritative palette")
editor.edit("legacy-v1")
local legacy_surface = assert(editor._state())
h.eq("full", legacy_surface.mode, "v1 theme opens in the full editor")
vim.cmd("write")
local upgraded = read_record("target", "legacy-v1")
h.eq(2, upgraded.version, "committing v1 upgrades it to v2")
h.eq("full", upgraded.mode, "v1 commit records full mode")
h.eq(legacy_palette, upgraded.palette, "v1 commit has no palette drift")
press("q")
vim.wait(20)

local invalid_records = {
	{
		name = "missing-mode",
		record = {
			version = 2,
			family = "modes",
			name = "missing-mode",
			background = "dark",
			palette = require("neotheme.neutral_palette").get("dark"),
		},
		expected = "missing field mode",
	},
	{
		name = "unknown-record-field",
		record = {
			version = 2,
			family = "modes",
			name = "unknown-record-field",
			background = "dark",
			mode = "full",
			palette = require("neotheme.neutral_palette").get("dark"),
			extra = true,
		},
		expected = "unknown field extra",
	},
	{
		name = "bad-mode",
		record = {
			version = 2,
			family = "modes",
			name = "bad-mode",
			background = "dark",
			mode = "compact",
			palette = require("neotheme.neutral_palette").get("dark"),
		},
		expected = "mode must be simplified or full",
	},
	{
		name = "simplified-nested",
		record = {
			version = 2,
			family = "modes",
			name = "simplified-nested",
			background = "dark",
			mode = "simplified",
			palette = require("neotheme.neutral_palette").get("dark"),
		},
		expected = "palette.surface_deepest must be a #RRGGBB color",
	},
	{
		name = "full-flat",
		record = {
			version = 2,
			family = "modes",
			name = "full-flat",
			background = "dark",
			mode = "full",
			palette = simplified_dark,
		},
		expected = "must be an object",
	},
}
local missing_source = copy(simplified_dark)
missing_source.text_muted = nil
table.insert(invalid_records, {
	name = "simplified-missing",
	record = {
		version = 2,
		family = "modes",
		name = "simplified-missing",
		background = "dark",
		mode = "simplified",
		palette = missing_source,
	},
	expected = "palette.text_muted must be a #RRGGBB color",
})
local unknown_source = copy(simplified_dark)
unknown_source.extra = "#010203"
table.insert(invalid_records, {
	name = "simplified-unknown",
	record = {
		version = 2,
		family = "modes",
		name = "simplified-unknown",
		background = "dark",
		mode = "simplified",
		palette = unknown_source,
	},
	expected = "unknown palette entry extra",
})
local invalid_color_source = copy(simplified_dark)
invalid_color_source.text_on_accent = "#123"
table.insert(invalid_records, {
	name = "simplified-color",
	record = {
		version = 2,
		family = "modes",
		name = "simplified-color",
		background = "dark",
		mode = "simplified",
		palette = invalid_color_source,
	},
	expected = "palette.text_on_accent must be a #RRGGBB color",
})
for _, invalid in ipairs(invalid_records) do
	write_record("modes", invalid.name, invalid.record)
end
local invalid_inventory = state.load()
for _, invalid in ipairs(invalid_records) do
	local matching_diagnostic = false
	for _, diagnostic in ipairs(invalid_inventory.diagnostics) do
		if
			diagnostic:find(invalid.name .. ".json:", 1, true)
			and diagnostic:find(invalid.expected, 1, true)
		then
			matching_diagnostic = true
			break
		end
	end
	h.truthy(matching_diagnostic, invalid.name .. " is isolated with a deterministic diagnostic")
	h.eq(nil, invalid_inventory.themes[invalid.name], invalid.name .. " is omitted from inventory")
	vim.fn.delete(record_path("modes", invalid.name))
end
