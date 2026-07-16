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

local function assert_noop(expected_theme, label)
	local before = runtime_state()
	local cached_discovered = require("lualine.themes.neotheme")
	local cached_lualine = require("neotheme.lualine")
	local original_set_hl = vim.api.nvim_set_hl
	local highlight_writes = 0
	vim.api.nvim_set_hl = function(...)
		highlight_writes = highlight_writes + 1
		return original_set_hl(...)
	end

	local returned = engine.reset()
	vim.api.nvim_set_hl = original_set_hl

	h.eq(expected_theme, returned, label .. " return value")
	h.eq(before, runtime_state(), label .. " runtime state")
	h.eq(0, highlight_writes, label .. " highlight churn")
	h.truthy(package.loaded["neotheme.lualine"] == cached_lualine, label .. " Lualine cache")
	h.truthy(
		package.loaded["lualine.themes.neotheme"] == cached_discovered,
		label .. " discovered Lualine cache"
	)
end

local default_theme = "gruber-dark-muted"
h.eq(false, engine.current().loaded, "default starts unloaded")
h.eq(default_theme, engine.reset(), "default pre-load reset return")
h.eq({
	loaded = true,
	active_theme = default_theme,
	family = "gruber",
	configured_theme = default_theme,
	background = "dark",
	session_override = false,
}, engine.current(), "default pre-load reset state")
h.eq(true, engine._snapshot_state().baseline_applied, "default reset applies baseline marker")
h.truthy(#autocmds() > 0, "default reset creates autocmds")
assert_noop(default_theme, "default baseline no-op")

vim.cmd.colorscheme("default")
local built_in_calls = 0
local setup_input = {
	theme = "gruber-dark",
	configure_palette = function(palette)
		built_in_calls = built_in_calls + 1
		palette.ui.search = palette.diagnostic.error
	end,
	bold = false,
	italic = { strings = false },
	underline = false,
	undercurl = false,
	integrations = { telescope = true },
}
local expected_input = vim.deepcopy(setup_input)
engine.setup(setup_input)
h.eq(expected_input, setup_input, "setup input remains unchanged")
h.eq(1, built_in_calls, "built-in setup resolves once")
h.eq(false, engine.current().loaded, "built-in setup remains unloaded")

local setup_lualine = require("neotheme.lualine")
h.eq("gruber-dark", engine.reset(), "built-in pre-load reset return")
h.eq(2, built_in_calls, "built-in reset re-resolves baseline")
h.eq({
	loaded = true,
	active_theme = "gruber-dark",
	family = "gruber",
	configured_theme = "gruber-dark",
	background = "dark",
	session_override = false,
}, engine.current(), "built-in pre-load reset state")
h.falsy(h.highlight("NeothemeKeyword").bold, "reset retains bold option")
h.falsy(h.highlight("NeothemeString").italic, "reset retains italic option")
h.falsy(h.highlight("Underlined").underline, "reset retains underline option")
h.falsy(h.highlight("SpellBad").undercurl, "reset retains undercurl option")
h.eq(
	h.color(engine.palette().ui.search),
	h.highlight("TelescopeMatching").fg,
	"reset regenerates enabled integration"
)
h.eq({}, h.highlight("CmpItemAbbrMatch"), "reset leaves disabled integration absent")
h.eq(engine.palette().surface.base, vim.g.terminal_color_background, "reset terminal background")
local reset_lualine = require("neotheme.lualine")
h.falsy(reset_lualine == setup_lualine, "reset invalidates Lualine discovery")
h.eq(engine.palette().surface.base, reset_lualine.normal.c.bg, "reset Lualine background")

local built_in_noop_calls = built_in_calls
assert_noop("gruber-dark", "configured built-in no-op")
h.eq(built_in_noop_calls, built_in_calls, "built-in no-op callback count")

engine.switch("typeset-paper")
engine.switch("arcfield-graphite")
h.eq("gruber-dark", engine.reset(), "multiple-switch reset return")
h.eq(5, built_in_calls, "multiple switches and reset each resolve once")
h.eq("gruber-dark", engine.current().active_theme, "multiple-switch reset target")
h.eq(false, engine.current().session_override, "multiple-switch reset clears override")
h.falsy(h.highlight("NeothemeKeyword").bold, "multiple-switch reset options")
h.eq(
	h.color(engine.palette().ui.search),
	h.highlight("TelescopeMatching").fg,
	"multiple-switch reset integration"
)

engine.switch("gruber-dark")
h.eq(true, engine._snapshot_state().baseline_applied, "switching to configured marks baseline")
local switched_configured_calls = built_in_calls
assert_noop("gruber-dark", "switch-configured no-op")
h.eq(switched_configured_calls, built_in_calls, "switch-configured callback count")

local same_theme_calls = 0
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		same_theme_calls = same_theme_calls + 1
		palette.ui.accent = palette.diagnostic.information
	end,
	bold = true,
	italic = { strings = true },
	integrations = { cmp = true },
})
h.eq(1, same_theme_calls, "same-theme setup resolves once")
h.eq("gruber-dark", engine.current().active_theme, "same-theme setup keeps old theme applied")
h.eq(false, engine.current().session_override, "same-theme setup has no override")
h.eq(false, engine._snapshot_state().baseline_applied, "same-theme setup marks baseline unapplied")
h.falsy(h.highlight("NeothemeKeyword").bold, "same-theme setup does not apply new options")

h.eq("gruber-dark", engine.reset(), "same-theme reset return")
h.eq(2, same_theme_calls, "same-theme reset re-resolves baseline")
h.eq(true, engine._snapshot_state().baseline_applied, "same-theme reset applies baseline marker")
h.eq(true, h.highlight("NeothemeKeyword").bold, "same-theme reset applies new bold option")
h.eq(true, h.highlight("NeothemeString").italic, "same-theme reset applies new italic option")
h.truthy(h.group_exists("CmpItemAbbrMatch"), "same-theme reset enables new integration")
h.eq({}, h.highlight("TelescopeMatching"), "same-theme reset clears old integration")

local replacement_calls = 0
engine.setup({
	theme = "typeset-paper",
	configure_palette = function()
		replacement_calls = replacement_calls + 1
	end,
	integrations = { gitsigns = true },
})
h.eq(1, replacement_calls, "replacement setup resolves once")
h.eq("gruber-dark", engine.current().active_theme, "replacement setup leaves old theme applied")
h.eq("typeset-paper", engine.reset(), "replacement reset return")
h.eq(2, replacement_calls, "replacement reset re-resolves baseline")
h.eq("typeset-paper", engine.current().active_theme, "replacement reset applies new theme")
h.eq("light", engine.current().background, "replacement reset applies new background")
h.truthy(h.group_exists("GitSignsAdd"), "replacement reset applies new integration")

local custom_reference = themes.get("ferric-forge")
local custom_calls = 0
local custom_empty_bases = {}
local custom_failure = false
local function configure_custom(palette)
	custom_calls = custom_calls + 1
	table.insert(custom_empty_bases, next(palette.surface) == nil)
	if custom_failure then
		error("intentional reset failure")
	end
	for category, values in pairs(custom_reference) do
		for field, color in pairs(values) do
			if palette[category][field] == nil then
				palette[category][field] = color
			end
		end
	end
end

vim.cmd.colorscheme("default")
engine.setup({ theme = "custom", configure_palette = configure_custom })
h.eq(1, custom_calls, "custom setup resolves once")
h.eq(true, custom_empty_bases[1], "custom setup receives empty base")
h.eq("custom", engine.reset(), "custom pre-load reset return")
h.eq(2, custom_calls, "custom reset re-resolves baseline")
h.eq(true, custom_empty_bases[2], "custom reset receives empty base")
h.eq(custom_reference, engine.palette(), "custom reset palette")
h.eq("custom", engine.current().active_theme, "custom reset active theme")
h.eq(false, engine.current().session_override, "custom reset override")

local custom_noop_calls = custom_calls
assert_noop("custom", "configured custom no-op")
h.eq(custom_noop_calls, custom_calls, "custom no-op callback count")

engine.switch("typeset-paper")
h.eq(false, custom_empty_bases[#custom_empty_bases], "custom-baseline switch gets built-in base")
local switched_lualine = require("neotheme.lualine")
h.eq("custom", engine.reset(), "custom override reset return")
h.eq(true, custom_empty_bases[#custom_empty_bases], "custom override reset gets empty base")
h.eq(custom_reference, engine.palette(), "custom override reset palette")
h.eq("custom", engine.current().active_theme, "custom override reset target")
h.falsy(require("neotheme.lualine") == switched_lualine, "custom reset refreshes Lualine")

vim.cmd.colorscheme("default")
h.eq("custom", engine.reset(), "external no-override reset return")
h.eq(true, engine.current().loaded, "external no-override reset loads Neotheme")

engine.switch("typeset-paper")
local before_loaded_failure = runtime_state()
local loaded_failure_discovered = require("lualine.themes.neotheme")
local loaded_failure_lualine = require("neotheme.lualine")
custom_failure = true
local loaded_ok, loaded_err = pcall(engine.reset)
h.falsy(loaded_ok, "loaded reset failure must fail")
h.truthy(tostring(loaded_err):find("intentional reset failure", 1, true), "loaded failure error")
h.eq(before_loaded_failure, runtime_state(), "loaded reset failure must be atomic")
h.truthy(
	package.loaded["neotheme.lualine"] == loaded_failure_lualine,
	"loaded failure Lualine cache"
)
h.truthy(
	package.loaded["lualine.themes.neotheme"] == loaded_failure_discovered,
	"loaded failure discovered Lualine cache"
)
custom_failure = false
h.eq("custom", engine.reset(), "loaded failure recovery reset")

engine.switch("typeset-paper")
vim.cmd.colorscheme("default")
local before_unloaded_failure = runtime_state()
local unloaded_failure_discovered = require("lualine.themes.neotheme")
local unloaded_failure_lualine = require("neotheme.lualine")
custom_failure = true
local unloaded_ok, unloaded_err = pcall(engine.reset)
h.falsy(unloaded_ok, "unloaded reset failure must fail")
h.truthy(
	tostring(unloaded_err):find("intentional reset failure", 1, true),
	"unloaded failure error"
)
h.eq(
	before_unloaded_failure,
	runtime_state(),
	"unloaded reset failure must preserve external state"
)
h.eq(false, engine.current().loaded, "unloaded failure remains unloaded")
h.eq(true, engine.current().session_override, "unloaded failure retains override")
h.truthy(
	package.loaded["neotheme.lualine"] == unloaded_failure_lualine,
	"unloaded failure Lualine cache"
)
h.truthy(
	package.loaded["lualine.themes.neotheme"] == unloaded_failure_discovered,
	"unloaded failure discovered Lualine cache"
)
custom_failure = false
h.eq("custom", engine.reset(), "unloaded failure recovery reset")

h.eq(0, vim.fn.exists(":NeothemeReset"), "reset command absent under --noplugin")
engine._register_commands()
engine._register_commands()
h.eq(2, vim.fn.exists(":NeothemeList"), "list command remains registered")
h.eq(2, vim.fn.exists(":NeothemeSwitch"), "switch command remains registered")
h.eq(2, vim.fn.exists(":NeothemeCurrent"), "current command remains registered")
h.eq(2, vim.fn.exists(":NeothemeReset"), "reset command registration is idempotent")
h.eq({}, vim.fn.getcompletion("NeothemeReset ", "cmdline"), "reset command has no completion")

engine.switch("typeset-paper")
local command_output = vim.api.nvim_exec2("NeothemeReset", { output = true }).output
h.eq("", command_output, "successful reset command is silent")
h.eq("custom", engine.current().active_theme, "reset command delegates to API")
h.eq(false, engine.current().session_override, "reset command clears override")

engine.switch("typeset-paper")
local invalid_before = runtime_state()
local original_reset = engine.reset
local reset_calls = 0
engine.reset = function()
	reset_calls = reset_calls + 1
	return original_reset()
end
local original_echo = vim.api.nvim_echo
local echo_count = 0
vim.api.nvim_echo = function(chunks, history, options)
	echo_count = echo_count + 1
	return original_echo(chunks, history, options)
end
local invalid_ok, invalid_err = pcall(vim.api.nvim_exec2, "NeothemeReset surplus", {
	output = true,
})
vim.api.nvim_echo = original_echo
engine.reset = original_reset

h.falsy(invalid_ok, "surplus reset arguments must fail")
h.truthy(
	tostring(invalid_err):find("accepts no arguments", 1, true),
	"surplus reset argument error"
)
h.eq(0, reset_calls, "surplus arguments must fail before reset")
h.eq(0, echo_count, "surplus arguments must not print output")
h.eq(invalid_before, runtime_state(), "surplus reset arguments must not mutate state")
