local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local engine = require("neotheme")
local themes = require("neotheme.themes")

local configured_theme = "gruber-dark"
local light_theme = "gruber-light"
local configurator_bases = {}

local function configure_palette(palette)
	table.insert(configurator_bases, palette.surface.base)
	palette.ui.search = palette.diagnostic.error
end

local function autocmd_count()
	local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = "Neotheme" })
	return ok and #autocmds or 0
end

local function visible_state()
	return {
		state = engine._state(),
		palette = engine.palette(),
		background = vim.o.background,
		colors_name = vim.g.colors_name,
		normal = h.highlight("Normal"),
		telescope = h.highlight("TelescopeMatching"),
		cmp = h.highlight("CmpItemAbbrMatch"),
		terminal_0 = vim.g.terminal_color_0,
		terminal_1 = vim.g.terminal_color_1,
		terminal_15 = vim.g.terminal_color_15,
		terminal_background = vim.g.terminal_color_background,
		terminal_foreground = vim.g.terminal_color_foreground,
		autocmd_count = autocmd_count(),
	}
end

local function assert_configured_options(label)
	h.falsy(h.highlight("NeothemeKeyword").bold, label .. " bold option")
	h.falsy(h.highlight("NeothemeString").italic, label .. " string italics")
	h.falsy(h.highlight("Underlined").underline, label .. " underline option")
	h.falsy(h.highlight("SpellBad").undercurl, label .. " undercurl option")
	h.eq(
		h.color(engine.palette().ui.search),
		h.highlight("TelescopeMatching").fg,
		label .. " enabled integration"
	)
	h.eq({}, h.highlight("CmpItemAbbrMatch"), label .. " disabled integration")
	h.eq(
		h.color(engine.palette().syntax.function_name),
		h.highlight("@function").fg,
		label .. " Tree-sitter palette"
	)
	h.eq(
		h.color(engine.palette().diagnostic.error),
		h.highlight("DiagnosticError").fg,
		label .. " LSP diagnostic palette"
	)
end

engine.setup({
	theme = configured_theme,
	configure_palette = configure_palette,
	bold = false,
	italic = { strings = false },
	underline = false,
	undercurl = false,
	integrations = {
		telescope = true,
		cmp = false,
	},
})
h.eq(1, #configurator_bases, "setup resolves its configured palette once")
h.eq(themes.get(configured_theme).surface.base, configurator_bases[1], "setup base palette")
h.eq({
	configured_theme = configured_theme,
	active_theme = nil,
	loaded = false,
	override_theme = nil,
}, engine._state(), "setup does not load highlights")

local configured_lualine = require("neotheme.lualine")
engine.switch(light_theme)

h.eq(2, #configurator_bases, "switch resolves its selected palette once")
h.eq(themes.get(light_theme).surface.base, configurator_bases[2], "light switch base palette")
h.eq({
	configured_theme = configured_theme,
	active_theme = light_theme,
	loaded = true,
	override_theme = light_theme,
}, engine._state(), "switch before load establishes an override")
h.eq("light", vim.o.background, "dark-to-light background")
h.eq("neotheme", vim.g.colors_name, "switch colorscheme name")
h.eq(h.color(engine.palette().surface.base), h.highlight("Normal").bg, "light core palette")
h.eq(engine.palette().surface.base, vim.g.terminal_color_background, "light terminal palette")
assert_configured_options("light switch")

local light_lualine = require("neotheme.lualine")
h.falsy(light_lualine == configured_lualine, "switch invalidates bundled Lualine discovery")
h.eq(engine.palette().ui.accent, light_lualine.normal.a.bg, "light Lualine accent")
h.eq(engine.palette().surface.base, light_lualine.normal.c.bg, "light Lualine background")

local stable_autocmd_count = autocmd_count()
h.truthy(stable_autocmd_count > 0, "switch creates Neotheme autocmds")

engine.switch(configured_theme)
h.eq(3, #configurator_bases, "return switch runs the configurator once")
h.eq(themes.get(configured_theme).surface.base, configurator_bases[3], "dark switch base")
h.eq({
	configured_theme = configured_theme,
	active_theme = configured_theme,
	loaded = true,
	override_theme = nil,
}, engine._state(), "switching to configured built-in clears the override")
h.eq("dark", vim.o.background, "light-to-dark background")
h.eq(h.color(engine.palette().surface.base), h.highlight("Normal").bg, "dark core palette")
h.eq(engine.palette().surface.base, vim.g.terminal_color_background, "dark terminal palette")
h.eq(stable_autocmd_count, autocmd_count(), "return switch keeps autocmd count stable")
assert_configured_options("dark switch")

local dark_lualine = require("neotheme.lualine")
h.falsy(dark_lualine == light_lualine, "repeated switches refresh Lualine discovery")
h.eq(engine.palette().surface.base, dark_lualine.normal.c.bg, "dark Lualine background")

engine.switch(light_theme)
engine.switch(light_theme)
h.eq(5, #configurator_bases, "every repeated switch resolves exactly once")
h.eq(stable_autocmd_count, autocmd_count(), "repeated switches do not duplicate autocmds")
assert_configured_options("repeated switch")

local before_invalid = visible_state()
local stable_discovered = require("lualine.themes.neotheme")
local stable_lualine = require("neotheme.lualine")

for _, case in ipairs({
	{ value = "missing-theme", message = "missing-theme" },
	{ value = "custom", message = "custom" },
	{ value = nil, message = "non-empty string" },
}) do
	local ok, err = pcall(engine.switch, case.value)
	h.falsy(ok, "invalid switch must fail: " .. tostring(case.value))
	h.truthy(tostring(err):find(case.message, 1, true), "invalid switch error: " .. case.message)
	h.eq(before_invalid, visible_state(), "invalid switch must not mutate runtime state")
	h.truthy(package.loaded["neotheme.lualine"] == stable_lualine, "invalid switch Lualine cache")
	h.truthy(
		package.loaded["lualine.themes.neotheme"] == stable_discovered,
		"invalid switch discovered Lualine cache"
	)
end

h.eq(0, vim.fn.exists(":NeothemeSwitch"), "switch command absent under --noplugin")
engine._register_commands()
engine._register_commands()
h.eq(2, vim.fn.exists(":NeothemeSwitch"), "switch command registration is idempotent")

local built_ins = {}
for _, theme in ipairs(engine.themes()) do
	if theme ~= "custom" then
		table.insert(built_ins, theme)
	end
end
h.eq(built_ins, vim.fn.getcompletion("NeothemeSwitch ", "cmdline"), "built-in completion")
h.eq({
	"gruber-dark",
	"gruber-dark-muted",
	"gruber-darker",
	"gruber-light",
	"gruber-light-muted",
	"gruber-lighter",
}, vim.fn.getcompletion("NeothemeSwitch gruber-", "cmdline"), "switch prefix completion")

for _, case in ipairs({
	{ command = "NeothemeSwitch", message = "requires a theme argument" },
	{ command = "NeothemeSwitch custom", message = "custom" },
	{ command = "NeothemeSwitch missing-theme", message = "missing-theme" },
	{ command = "NeothemeSwitch gruber-dark extra", message = "exactly one theme argument" },
}) do
	local command_before = visible_state()
	local command_lualine = require("neotheme.lualine")
	local command_discovered = require("lualine.themes.neotheme")
	local ok, err = pcall(vim.api.nvim_exec2, case.command, { output = true })
	h.falsy(ok, "invalid switch command must fail: " .. case.command)
	h.truthy(tostring(err):find(case.message, 1, true), "switch command error: " .. case.message)
	h.eq(command_before, visible_state(), "invalid switch command must be atomic")
	h.truthy(package.loaded["neotheme.lualine"] == command_lualine, "command Lualine cache")
	h.truthy(
		package.loaded["lualine.themes.neotheme"] == command_discovered,
		"command discovered Lualine cache"
	)
end

vim.cmd("NeothemeSwitch " .. configured_theme)
h.eq(configured_theme, engine._state().active_theme, "command delegates to switch API")
h.eq(nil, engine._state().override_theme, "command clears matching configured override")
vim.cmd("NeothemeSwitch " .. light_theme)
h.eq(light_theme, engine._state().override_theme, "command establishes session override")
assert_configured_options("command switch")

local override_palette = engine.palette()
vim.cmd.colorscheme("default")
h.eq({
	configured_theme = configured_theme,
	active_theme = nil,
	loaded = false,
	override_theme = light_theme,
}, engine._state(), "external colorscheme retains the selected override")
h.eq(override_palette, engine.palette(), "external colorscheme retains the resolved palette")
h.eq(0, autocmd_count(), "external colorscheme removes Neotheme autocmds")
local unloaded = engine._snapshot_state()
h.eq(nil, unloaded.applied_theme, "external colorscheme clears applied theme")
h.eq(nil, unloaded.applied_options, "external colorscheme clears applied options")
h.eq(nil, unloaded.applied_palette, "external colorscheme clears applied palette")
h.eq(light_theme, unloaded.override_theme, "external colorscheme retains override name")

engine.load()
h.eq({
	configured_theme = configured_theme,
	active_theme = configured_theme,
	loaded = true,
	override_theme = nil,
}, engine._state(), "load reapplies the configured baseline and clears override")
h.eq("dark", vim.o.background, "load restores configured background")
h.eq(
	override_palette.surface.base ~= engine.palette().surface.base,
	true,
	"load restores baseline palette"
)
assert_configured_options("configured load")
