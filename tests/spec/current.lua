local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local config = require("neotheme.config")
local engine = require("neotheme")
local themes = require("neotheme.themes")

local custom_reference = themes.get("ferric-forge")

local function fill_custom(palette)
	for category, values in pairs(custom_reference) do
		for field, color in pairs(values) do
			palette[category][field] = color
		end
	end
end

local function autocmd_count()
	local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = "Neotheme" })
	return ok and #autocmds or 0
end

local function runtime_state()
	return {
		snapshot = engine._snapshot_state(),
		config = config.get(),
		palette = engine.palette(),
		background = vim.o.background,
		colors_name = vim.g.colors_name,
		normal = h.highlight("Normal"),
		terminal_0 = vim.g.terminal_color_0,
		terminal_1 = vim.g.terminal_color_1,
		terminal_15 = vim.g.terminal_color_15,
		terminal_background = vim.g.terminal_color_background,
		terminal_foreground = vim.g.terminal_color_foreground,
		autocmd_count = autocmd_count(),
	}
end

local function assert_current(expected, label)
	local actual = engine.current()
	h.eq(expected, actual, label)
	return actual
end

local function assert_command_output(expected, label)
	local original_echo = vim.api.nvim_echo
	local echoes = {}
	vim.api.nvim_echo = function(chunks, history, options)
		table.insert(echoes, { chunks = chunks, history = history, options = options })
		return original_echo(chunks, history, options)
	end

	local output = vim.api.nvim_exec2("NeothemeCurrent", { output = true }).output
	vim.api.nvim_echo = original_echo

	h.eq(expected, output, label .. " output")
	h.eq(1, #echoes, label .. " echo count")
	h.eq(true, echoes[1].history, label .. " message history")
end

h.eq("gruber", themes.family("gruber-dark-muted"), "explicit family lookup")
h.eq("typeset", themes.family("typeset-paper"), "explicit cross-family lookup")
h.eq(nil, themes.family("custom"), "custom family lookup")
local family_ok, family_err = pcall(themes.family, "missing-theme")
h.falsy(family_ok, "unknown family lookup theme must fail")
h.truthy(tostring(family_err):find("missing-theme", 1, true), "family lookup error")

local initial_snapshot = engine._snapshot_state()
h.eq(nil, initial_snapshot.resolved_palette, "initial public palette is unresolved")
assert_current({
	loaded = false,
	configured_theme = "gruber-dark-muted",
	session_override = false,
}, "never-loaded default")
h.eq(initial_snapshot, engine._snapshot_state(), "current must not resolve initial state")

h.eq(0, vim.fn.exists(":NeothemeCurrent"), "current command absent under --noplugin")
engine._register_commands()
engine._register_commands()
h.eq(2, vim.fn.exists(":NeothemeList"), "list command remains registered")
h.eq(2, vim.fn.exists(":NeothemeSwitch"), "switch command remains registered")
h.eq(2, vim.fn.exists(":NeothemeCurrent"), "current command registration is idempotent")
assert_command_output(
	"active: not loaded\nconfigured: gruber-dark-muted\nsession override: no",
	"never-loaded default"
)

local built_in_calls = 0
engine.setup({
	theme = "gruber-dark",
	configure_palette = function()
		built_in_calls = built_in_calls + 1
	end,
})
h.eq(1, built_in_calls, "built-in setup resolves once")
assert_current({
	loaded = false,
	configured_theme = "gruber-dark",
	session_override = false,
}, "setup built-in before load")
h.eq(1, built_in_calls, "current does not rerun built-in configurator")

local custom_unloaded_calls = 0
engine.setup({
	theme = "custom",
	configure_palette = function(palette)
		custom_unloaded_calls = custom_unloaded_calls + 1
		fill_custom(palette)
	end,
})
h.eq(1, custom_unloaded_calls, "custom setup resolves once")
assert_current({
	loaded = false,
	configured_theme = "custom",
	session_override = false,
}, "setup custom before load")
h.eq(1, custom_unloaded_calls, "current does not rerun custom configurator")

local configured_calls = 0
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		configured_calls = configured_calls + 1
		palette.ui.search = palette.diagnostic.error
	end,
})
engine.load()
h.eq(1, configured_calls, "load reuses configured palette")
assert_current({
	loaded = true,
	active_theme = "gruber-dark",
	family = "gruber",
	configured_theme = "gruber-dark",
	background = "dark",
	session_override = false,
}, "normal built-in load")
assert_command_output(
	"active: gruber-dark\nfamily: gruber\nconfigured: gruber-dark\nbackground: dark\nsession override: no",
	"normal built-in load"
)

engine.switch("typeset-paper")
assert_current({
	loaded = true,
	active_theme = "typeset-paper",
	family = "typeset",
	configured_theme = "gruber-dark",
	background = "light",
	session_override = true,
}, "live override")
assert_command_output(
	"active: typeset-paper\nfamily: typeset\nconfigured: gruber-dark\nbackground: light\nsession override: yes",
	"live override"
)

engine.switch("gruber-dark")
assert_current({
	loaded = true,
	active_theme = "gruber-dark",
	family = "gruber",
	configured_theme = "gruber-dark",
	background = "dark",
	session_override = false,
}, "restored configured theme")

vim.cmd.colorscheme("default")
assert_current({
	loaded = false,
	configured_theme = "gruber-dark",
	session_override = false,
}, "external colorscheme without override")

engine.switch("typeset-paper")
vim.cmd.colorscheme("default")
assert_current({
	loaded = false,
	configured_theme = "gruber-dark",
	session_override = true,
}, "external colorscheme with retained override")
assert_command_output(
	"active: not loaded\nconfigured: gruber-dark\nsession override: yes",
	"external colorscheme with retained override"
)

engine.load()
engine.setup({ theme = "typewriter-ink" })
assert_current({
	loaded = true,
	active_theme = "gruber-dark",
	family = "gruber",
	configured_theme = "typewriter-ink",
	background = "dark",
	session_override = false,
}, "new built-in setup while old built-in is loaded")

engine.setup({
	theme = "custom",
	configure_palette = fill_custom,
})
assert_current({
	loaded = true,
	active_theme = "gruber-dark",
	family = "gruber",
	configured_theme = "custom",
	background = "dark",
	session_override = false,
}, "custom setup while old built-in is loaded")

engine.load()
assert_current({
	loaded = true,
	active_theme = "custom",
	configured_theme = "custom",
	background = "dark",
	session_override = false,
}, "loaded custom")
assert_command_output(
	"active: custom\nconfigured: custom\nbackground: dark\nsession override: no",
	"loaded custom"
)

engine.setup({ theme = "typeset-paper" })
assert_current({
	loaded = true,
	active_theme = "custom",
	configured_theme = "typeset-paper",
	background = "dark",
	session_override = false,
}, "new built-in setup while custom is loaded")

local before_failed_setup = engine.current()
local failed_ok = pcall(engine.setup, { theme = "missing-theme" })
h.falsy(failed_ok, "failed setup must fail")
h.eq(before_failed_setup, engine.current(), "failed setup preserves current state")

local custom_calls = 0
engine.setup({
	theme = "custom",
	configure_palette = function(palette)
		custom_calls = custom_calls + 1
		fill_custom(palette)
	end,
})
engine.load()
h.eq(1, custom_calls, "custom load reuses setup palette")
engine.switch("typeset-paper")
h.eq(2, custom_calls, "custom-baseline switch resolves once")
assert_current({
	loaded = true,
	active_theme = "typeset-paper",
	family = "typeset",
	configured_theme = "custom",
	background = "light",
	session_override = true,
}, "configured custom switched to built-in")

local defensive = engine.current()
local expected_current = engine.current()
h.falsy(defensive == expected_current, "current returns a fresh table")
defensive.loaded = false
defensive.active_theme = "injected"
defensive.family = "injected"
defensive.configured_theme = "injected"
defensive.background = "dark"
defensive.session_override = false
defensive.extra = true
h.eq(expected_current, engine.current(), "current state must be defensive")

local before_reads = runtime_state()
local cached_discovered = require("lualine.themes.neotheme")
local cached_lualine = require("neotheme.lualine")
local calls_before_reads = custom_calls
for _ = 1, 5 do
	h.eq(expected_current, engine.current(), "repeated current state")
end
h.eq(calls_before_reads, custom_calls, "current never reruns configurator")
h.eq(before_reads, runtime_state(), "current must not mutate editor or engine state")
h.truthy(package.loaded["neotheme.lualine"] == cached_lualine, "current Lualine cache")
h.truthy(
	package.loaded["lualine.themes.neotheme"] == cached_discovered,
	"current discovered Lualine cache"
)

local invalid_before = runtime_state()
local original_current = engine.current
local current_calls = 0
engine.current = function()
	current_calls = current_calls + 1
	return original_current()
end
local original_echo = vim.api.nvim_echo
local echo_count = 0
vim.api.nvim_echo = function(chunks, history, options)
	echo_count = echo_count + 1
	return original_echo(chunks, history, options)
end
local invalid_ok, invalid_err = pcall(vim.api.nvim_exec2, "NeothemeCurrent surplus", {
	output = true,
})
vim.api.nvim_echo = original_echo
engine.current = original_current

h.falsy(invalid_ok, "surplus current arguments must fail")
h.truthy(
	tostring(invalid_err):find("accepts no arguments", 1, true),
	"surplus current argument error"
)
h.eq(0, current_calls, "surplus arguments must fail before state read")
h.eq(0, echo_count, "surplus arguments must not print partial output")
h.eq(invalid_before, runtime_state(), "surplus arguments must not mutate state")
