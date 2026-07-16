local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local config = require("neotheme.config")
local engine = require("neotheme")
local themes = require("neotheme.themes")

local function autocmds()
	local ok, definitions = pcall(vim.api.nvim_get_autocmds, { group = "Neotheme" })
	if not ok then
		return {}
	end

	local result = {}
	for _, definition in ipairs(definitions) do
		table.insert(result, {
			id = definition.id,
			event = definition.event,
			pattern = definition.pattern,
			desc = definition.desc,
		})
	end
	return result
end

local function runtime_state()
	return {
		current = engine.current(),
		snapshot = engine._snapshot_state(),
		config = config.get(),
		palette = engine.palette(),
		background = vim.o.background,
		colors_name = vim.g.colors_name,
		normal = h.highlight("Normal"),
		keyword = h.highlight("NeothemeKeyword"),
		string = h.highlight("NeothemeString"),
		function_name = h.highlight("@function"),
		diagnostic = h.highlight("DiagnosticError"),
		telescope = h.highlight("TelescopeMatching"),
		cmp = h.highlight("CmpItemAbbrMatch"),
		gitsigns = h.highlight("GitSignsAdd"),
		terminal_0 = vim.g.terminal_color_0,
		terminal_1 = vim.g.terminal_color_1,
		terminal_15 = vim.g.terminal_color_15,
		terminal_background = vim.g.terminal_color_background,
		terminal_foreground = vim.g.terminal_color_foreground,
		autocmds = autocmds(),
	}
end

local function assert_reload_failure(label, expected_message)
	local before = runtime_state()
	local cached_lualine = require("neotheme.lualine")
	local cached_discovered = require("lualine.themes.neotheme")
	local ok, err = pcall(engine.reload)

	h.falsy(ok, label .. " must fail")
	h.truthy(tostring(err):find(expected_message, 1, true), label .. " error")
	h.eq(before, runtime_state(), label .. " must preserve runtime state")
	h.truthy(package.loaded["neotheme.lualine"] == cached_lualine, label .. " Lualine cache")
	h.truthy(
		package.loaded["lualine.themes.neotheme"] == cached_discovered,
		label .. " discovered Lualine cache"
	)
end

local default_theme = "gruber-dark-muted"
h.eq(false, engine.current().loaded, "default starts unloaded")
h.eq(default_theme, engine.reload(), "default reload return")
h.eq({
	loaded = true,
	active_theme = default_theme,
	family = "gruber",
	configured_theme = default_theme,
	background = "dark",
	session_override = false,
}, engine.current(), "default reload state")
h.eq(true, engine._snapshot_state().baseline_applied, "default reload baseline marker")
h.truthy(#autocmds() > 0, "default reload creates autocmds")

vim.cmd.colorscheme("default")
local configured_calls = 0
local configured_bases = {}
local configured_accent = "#e06b63"
local setup_input = {
	theme = "gruber-dark",
	configure_palette = function(palette)
		configured_calls = configured_calls + 1
		table.insert(configured_bases, palette.ui.accent)
		palette.ui.accent = configured_accent
		palette.ui.search = configured_accent
	end,
	bold = false,
	italic = { strings = false },
	underline = false,
	undercurl = false,
	integrations = { telescope = true, cmp = false },
}
local expected_setup_input = vim.deepcopy(setup_input)
engine.setup(setup_input)
h.eq(expected_setup_input, setup_input, "reload setup input remains unchanged")
h.eq(1, configured_calls, "configured setup resolves once")
h.eq(false, engine.current().loaded, "configured setup remains unloaded")

configured_accent = "#93c476"
local setup_lualine = require("neotheme.lualine")
h.eq("gruber-dark", engine.reload(), "configured pre-load reload return")
h.eq(2, configured_calls, "configured reload resolves once")
h.eq(configured_bases[1], configured_bases[2], "configured reload uses a fresh base")
h.eq(configured_accent, engine.palette().ui.accent, "configured reload palette")
h.eq(configured_accent, engine._snapshot_state().configured_palette.ui.accent, "configured cache")
h.eq(true, engine._snapshot_state().baseline_applied, "configured reload baseline marker")
h.falsy(h.highlight("NeothemeKeyword").bold, "configured reload bold option")
h.falsy(h.highlight("NeothemeString").italic, "configured reload italic option")
h.falsy(h.highlight("Underlined").underline, "configured reload underline option")
h.falsy(h.highlight("SpellBad").undercurl, "configured reload undercurl option")
h.eq(h.color(configured_accent), h.highlight("TelescopeMatching").fg, "configured integration")
h.eq({}, h.highlight("CmpItemAbbrMatch"), "configured disabled integration")
h.eq(engine.palette().surface.base, vim.g.terminal_color_background, "configured terminal")
local configured_lualine = require("neotheme.lualine")
h.falsy(configured_lualine == setup_lualine, "configured reload invalidates Lualine")
h.eq(configured_accent, configured_lualine.normal.a.bg, "configured Lualine accent")

local stable_autocmd_count = #autocmds()
configured_accent = "#6aa9e9"
local repeated_lualine = configured_lualine
h.eq("gruber-dark", engine.reload(), "repeated configured reload return")
h.eq(3, configured_calls, "repeated configured reload resolves once")
h.eq(configured_bases[1], configured_bases[3], "repeated reload does not accumulate mutations")
h.eq(stable_autocmd_count, #autocmds(), "repeated reload keeps autocmd count stable")
h.eq(h.color(configured_accent), h.highlight("Title").fg, "repeated reload refreshes highlights")
h.falsy(require("neotheme.lualine") == repeated_lualine, "repeated reload refreshes Lualine")
local calls_before_noop_reset = configured_calls
h.eq("gruber-dark", engine.reset(), "configured reload reset return")
h.eq(calls_before_noop_reset, configured_calls, "configured reload makes reset a no-op")

vim.cmd.colorscheme("default")
engine.load()
h.eq(3, configured_calls, "load reuses last configured reload cache")
h.eq(configured_accent, engine.palette().ui.accent, "load applies last configured reload cache")

local configured_cache = engine._snapshot_state().configured_palette
configured_accent = "#d8a657"
engine.switch("typeset-paper")
h.eq(4, configured_calls, "override switch resolves once")
local override_cache = engine._snapshot_state().configured_palette
h.eq(configured_cache, override_cache, "override switch preserves configured cache")
configured_accent = "#d3869b"
local override_lualine = require("neotheme.lualine")
h.eq("typeset-paper", engine.reload(), "override reload return")
h.eq(5, configured_calls, "override reload resolves once")
h.eq(
	themes.get("typeset-paper").ui.accent,
	configured_bases[5],
	"override reload gets a fresh override base"
)
h.eq("typeset-paper", engine.current().active_theme, "override reload active theme")
h.eq("gruber-dark", engine.current().configured_theme, "override reload configured theme")
h.eq(true, engine.current().session_override, "override reload retains selection")
h.eq(false, engine._snapshot_state().baseline_applied, "override reload baseline marker")
h.eq(override_cache, engine._snapshot_state().configured_palette, "override reload cache")
h.eq(h.color(configured_accent), h.highlight("Title").fg, "override reload highlight")
h.falsy(require("neotheme.lualine") == override_lualine, "override reload refreshes Lualine")

vim.cmd.colorscheme("default")
h.eq(false, engine.current().loaded, "external colorscheme unloads override")
h.eq(true, engine.current().session_override, "external colorscheme retains override")
configured_accent = "#fe8019"
h.eq("typeset-paper", engine.reload(), "retained override reload return")
h.eq(6, configured_calls, "retained override reload resolves once")
h.eq(true, engine.current().loaded, "retained override reload loads Neotheme")
h.eq(true, engine.current().session_override, "retained override reload keeps override")
h.eq(override_cache, engine._snapshot_state().configured_palette, "retained override cache")

h.eq("gruber-dark", engine.reset(), "override reset returns configured theme")
h.eq(7, configured_calls, "override reset re-resolves configured theme")
h.eq(false, engine.current().session_override, "override reset clears selection")
h.eq(true, engine._snapshot_state().baseline_applied, "override reset baseline marker")
h.eq("dark", engine.current().background, "override reset restores configured background")

local custom_reference = themes.get("ferric-forge")
local custom_calls = 0
local custom_empty_bases = {}
local custom_accent = "#b8bb26"
local function configure_custom(palette)
	custom_calls = custom_calls + 1
	table.insert(custom_empty_bases, next(palette.surface) == nil)
	for category, values in pairs(custom_reference) do
		for field, color in pairs(values) do
			if palette[category][field] == nil then
				palette[category][field] = color
			end
		end
	end
	palette.ui.accent = custom_accent
end

vim.cmd.colorscheme("default")
engine.setup({ theme = "custom", configure_palette = configure_custom })
h.eq(1, custom_calls, "custom setup resolves once")
custom_accent = "#fabd2f"
h.eq("custom", engine.reload(), "custom pre-load reload return")
h.eq(2, custom_calls, "custom reload resolves once")
h.eq({ true, true }, custom_empty_bases, "custom reload always receives empty base")
h.eq(custom_accent, engine.palette().ui.accent, "custom reload palette")
h.eq(true, engine._snapshot_state().baseline_applied, "custom reload baseline marker")

custom_accent = "#8ec07c"
h.eq("custom", engine.reload(), "repeated custom reload return")
h.eq(3, custom_calls, "repeated custom reload resolves once")
h.eq({ true, true, true }, custom_empty_bases, "repeated custom reload gets a fresh empty base")
h.eq(custom_accent, engine.palette().ui.accent, "repeated custom reload palette")

local custom_cache = engine._snapshot_state().configured_palette
engine.switch("typeset-paper")
h.eq(false, custom_empty_bases[4], "custom override switch receives built-in base")
custom_accent = "#83a598"
h.eq("typeset-paper", engine.reload(), "custom-baseline override reload return")
h.eq(false, custom_empty_bases[5], "custom-baseline override reload receives built-in base")
h.eq("custom", engine.current().configured_theme, "custom baseline remains selected")
h.eq(true, engine.current().session_override, "custom baseline retains override")
h.eq(custom_cache, engine._snapshot_state().configured_palette, "custom override preserves cache")
h.eq("custom", engine.reset(), "custom override reset return")
h.eq(true, custom_empty_bases[6], "custom reset receives empty base")

engine.setup({
	theme = "gruber-light",
	bold = false,
	integrations = { cmp = true },
})
h.eq("custom", engine.current().active_theme, "setup leaves old custom applied")
h.eq(false, engine._snapshot_state().baseline_applied, "setup marks new baseline unapplied")
h.eq("gruber-light", engine.reload(), "setup-while-loaded reload target")
h.eq("gruber-light", engine.current().active_theme, "reload applies latest configured theme")
h.eq("light", engine.current().background, "reload applies latest configured background")
h.falsy(h.highlight("NeothemeKeyword").bold, "reload applies latest configured options")
h.truthy(h.group_exists("CmpItemAbbrMatch"), "reload applies latest configured integration")

local same_theme_calls = 0
engine.setup({
	theme = "gruber-light",
	configure_palette = function(palette)
		same_theme_calls = same_theme_calls + 1
		palette.ui.search = palette.diagnostic.warning
	end,
	bold = true,
	integrations = { telescope = true, cmp = false },
})
h.eq(1, same_theme_calls, "same-theme setup resolves once")
h.eq(false, engine._snapshot_state().baseline_applied, "same-theme setup marker")
h.eq("gruber-light", engine.reload(), "same-theme reload return")
h.eq(2, same_theme_calls, "same-theme reload resolves once")
h.eq(true, h.highlight("NeothemeKeyword").bold, "same-theme reload applies changed option")
h.truthy(h.group_exists("TelescopeMatching"), "same-theme reload enables integration")
h.eq({}, h.highlight("CmpItemAbbrMatch"), "same-theme reload clears disabled integration")

vim.cmd.colorscheme("default")
h.eq("gruber-light", engine.reload(), "external configured reload return")
h.eq(3, same_theme_calls, "external configured reload resolves once")
h.eq(true, engine.current().loaded, "external configured reload loads Neotheme")
h.eq(false, engine.current().session_override, "external configured reload has no override")

engine.setup({ theme = "custom", configure_palette = configure_custom })
h.eq("gruber-light", engine.current().active_theme, "custom setup leaves built-in applied")
h.eq("custom", engine.reload(), "built-in-to-custom reload target")
h.eq("custom", engine.current().active_theme, "built-in-to-custom reload applies custom")

local failure_calls = 0
local failure_enabled = false
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		failure_calls = failure_calls + 1
		if failure_enabled then
			error("intentional reload failure")
		end
		palette.ui.accent = palette.diagnostic.success
	end,
	integrations = { gitsigns = true },
})
h.eq("gruber-dark", engine.reload(), "failure fixture configured reload")
h.eq(2, failure_calls, "failure fixture setup and reload count")
failure_enabled = true
assert_reload_failure("loaded configured reload failure", "intentional reload failure")
h.eq(3, failure_calls, "loaded configured failure invokes callback once")

failure_enabled = false
engine.switch("typeset-paper")
h.eq(4, failure_calls, "failure fixture override switch")
failure_enabled = true
assert_reload_failure("loaded override reload failure", "intentional reload failure")
h.eq(5, failure_calls, "loaded override failure invokes callback once")

vim.cmd.colorscheme("default")
assert_reload_failure("unloaded retained override reload failure", "intentional reload failure")
h.eq(6, failure_calls, "unloaded retained override failure invokes callback once")
h.eq(false, engine.current().loaded, "retained override failure remains unloaded")
h.eq(true, engine.current().session_override, "retained override failure keeps override")

failure_enabled = false
engine.setup({
	theme = "gruber-light",
	configure_palette = config.get().configure_palette,
	integrations = { gitsigns = true },
})
h.eq(7, failure_calls, "pre-load failure fixture setup")
failure_enabled = true
assert_reload_failure("pre-load configured reload failure", "intentional reload failure")
h.eq(8, failure_calls, "pre-load configured failure invokes callback once")
h.eq(false, engine.current().loaded, "pre-load failure remains unloaded")
h.eq(false, engine.current().session_override, "pre-load failure has no override")

h.eq(0, vim.fn.exists(":NeothemeReload"), "reload command absent under --noplugin")
engine._register_commands()
engine._register_commands()
h.eq(2, vim.fn.exists(":NeothemeList"), "list command remains registered")
h.eq(2, vim.fn.exists(":NeothemeSwitch"), "switch command remains registered")
h.eq(2, vim.fn.exists(":NeothemeCurrent"), "current command remains registered")
h.eq(2, vim.fn.exists(":NeothemeReset"), "reset command remains registered")
h.eq(2, vim.fn.exists(":NeothemeReload"), "reload command registration is idempotent")
h.eq({}, vim.fn.getcompletion("NeothemeReload ", "cmdline"), "reload command has no completion")

failure_enabled = false
local command_output = vim.api.nvim_exec2("NeothemeReload", { output = true }).output
h.eq("", command_output, "successful reload command is silent")
h.eq("gruber-light", engine.current().active_theme, "reload command delegates to API")

local invalid_before = runtime_state()
local original_reload = engine.reload
local reload_calls = 0
engine.reload = function()
	reload_calls = reload_calls + 1
	return original_reload()
end
local original_echo = vim.api.nvim_echo
local echo_count = 0
vim.api.nvim_echo = function(chunks, history, options)
	echo_count = echo_count + 1
	return original_echo(chunks, history, options)
end
local invalid_ok, invalid_err = pcall(vim.api.nvim_exec2, "NeothemeReload surplus", {
	output = true,
})
vim.api.nvim_echo = original_echo
engine.reload = original_reload

h.falsy(invalid_ok, "surplus reload arguments must fail")
h.truthy(
	tostring(invalid_err):find("accepts no arguments", 1, true),
	"surplus reload argument error"
)
h.eq(0, reload_calls, "surplus arguments must fail before reload")
h.eq(0, echo_count, "surplus arguments must not print output")
h.eq(invalid_before, runtime_state(), "surplus reload arguments must not mutate state")
