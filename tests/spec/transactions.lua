local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local config = require("neotheme.config")
local engine = require("neotheme")
local themes = require("neotheme.themes")

local baseline_calls = 0
local function configure_baseline(palette)
	baseline_calls = baseline_calls + 1
	palette.ui.search = palette.diagnostic.error
end

local function autocmd_count()
	local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = "Neotheme" })
	return ok and #autocmds or 0
end

local function visible_state()
	return {
		state = engine._state(),
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
		terminal_0 = vim.g.terminal_color_0,
		terminal_1 = vim.g.terminal_color_1,
		terminal_15 = vim.g.terminal_color_15,
		terminal_background = vim.g.terminal_color_background,
		terminal_foreground = vim.g.terminal_color_foreground,
		autocmd_count = autocmd_count(),
	}
end

local function assert_snapshot_restoration(snapshot, preview_theme, counter, label)
	local calls_before_preview = counter()
	engine.switch(preview_theme)
	h.eq(calls_before_preview + 1, counter(), label .. " preview configurator")
	local calls_before_restore = counter()
	engine._restore_state(snapshot)
	h.eq(calls_before_restore, counter(), label .. " restore must not rerun configurator")
	h.eq(snapshot, engine._snapshot_state(), label .. " exact state restoration")
	h.eq(
		h.color(snapshot.applied_palette.surface.base),
		h.highlight("Normal").bg,
		label .. " applied palette restoration"
	)
end

engine.switch("gruber-light")
local optional_cache_snapshot = engine._snapshot_state()
h.eq(nil, optional_cache_snapshot.configured_palette, "pre-load switch has no configured cache")
engine.switch("typeset-ink")
engine._restore_state(optional_cache_snapshot)
h.eq(optional_cache_snapshot, engine._snapshot_state(), "optional configured cache restoration")
vim.cmd.colorscheme("default")

engine.setup({
	theme = "gruber-dark",
	configure_palette = configure_baseline,
	bold = false,
	italic = { strings = false },
	integrations = { telescope = true },
})
engine.load()
h.eq(1, baseline_calls, "configured palette is reused by load")

local configured_snapshot = engine._snapshot_state()
h.eq("gruber-dark", configured_snapshot.applied_theme, "configured snapshot theme")
h.eq(nil, configured_snapshot.override_theme, "configured snapshot override")
h.eq(true, configured_snapshot.baseline_applied, "configured snapshot baseline marker")
assert_snapshot_restoration(configured_snapshot, "gruber-light", function()
	return baseline_calls
end, "configured")
local configured_noop_calls = baseline_calls
h.eq("gruber-dark", engine.reset(), "restored configured reset return")
h.eq(configured_noop_calls, baseline_calls, "restored configured reset is a no-op")
h.eq(configured_snapshot, engine._snapshot_state(), "restored configured marker remains exact")

engine.switch("gruber-light")
local overridden_snapshot = engine._snapshot_state()
h.eq("gruber-light", overridden_snapshot.applied_theme, "override snapshot theme")
h.eq("gruber-light", overridden_snapshot.override_theme, "override snapshot selection")
h.eq(false, overridden_snapshot.baseline_applied, "override snapshot baseline marker")
assert_snapshot_restoration(overridden_snapshot, "typeset-ink", function()
	return baseline_calls
end, "overridden")

local defensive_snapshot = engine._snapshot_state()
local expected_snapshot = engine._snapshot_state()
defensive_snapshot.applied_options.bold = true
defensive_snapshot.applied_palette.surface.base =
	defensive_snapshot.applied_palette.diagnostic.error
defensive_snapshot.resolved_palette.syntax.string =
	defensive_snapshot.resolved_palette.diagnostic.hint
defensive_snapshot.configured_palette.ui.accent =
	defensive_snapshot.configured_palette.diagnostic.warning
defensive_snapshot.override_theme = "injected"
h.eq(expected_snapshot, engine._snapshot_state(), "returned snapshots must be defensive")

local before_failed_setup = visible_state()
local cached_discovered = require("lualine.themes.neotheme")
local cached_lualine = require("neotheme.lualine")

local unknown_ok, unknown_err = pcall(engine.setup, { theme = "missing-theme" })
h.falsy(unknown_ok, "unknown setup theme must fail")
h.truthy(tostring(unknown_err):find("missing-theme", 1, true), "unknown setup error")
h.eq(before_failed_setup, visible_state(), "unknown setup must preserve complete state")
h.truthy(package.loaded["neotheme.lualine"] == cached_lualine, "unknown setup Lualine cache")
h.truthy(
	package.loaded["lualine.themes.neotheme"] == cached_discovered,
	"unknown setup discovered Lualine cache"
)

local failed_configurator_calls = 0
local configurator_ok, configurator_err = pcall(engine.setup, {
	theme = "typeset-paper",
	configure_palette = function()
		failed_configurator_calls = failed_configurator_calls + 1
		error("intentional configurator failure")
	end,
})
h.falsy(configurator_ok, "failed setup configurator must fail")
h.truthy(
	tostring(configurator_err):find("intentional configurator failure", 1, true),
	"failed setup configurator error"
)
h.eq(1, failed_configurator_calls, "failed setup invokes its configurator once")
h.eq(before_failed_setup, visible_state(), "failed configurator setup must preserve complete state")
h.truthy(package.loaded["neotheme.lualine"] == cached_lualine, "failed setup Lualine cache")
h.truthy(
	package.loaded["lualine.themes.neotheme"] == cached_discovered,
	"failed setup discovered Lualine cache"
)

local old_visible_palette = overridden_snapshot.applied_palette
local replacement_calls = 0
engine.setup({
	theme = "typeset-paper",
	configure_palette = function(palette)
		replacement_calls = replacement_calls + 1
		palette.ui.accent = palette.diagnostic.information
	end,
	bold = true,
	integrations = { cmp = true },
})
h.eq(1, replacement_calls, "successful replacement setup resolves once")
h.eq({
	configured_theme = "typeset-paper",
	active_theme = "gruber-light",
	loaded = true,
	override_theme = nil,
}, engine._state(), "setup replaces baseline without applying it")
h.eq(
	themes.get("typeset-paper").surface.base,
	engine.palette().surface.base,
	"setup public palette"
)
h.eq(
	h.color(old_visible_palette.surface.base),
	h.highlight("Normal").bg,
	"setup leaves the previous applied palette visible"
)
h.falsy(h.highlight("NeothemeKeyword").bold, "setup leaves previous applied options visible")
h.eq(
	h.color(old_visible_palette.ui.search),
	h.highlight("TelescopeMatching").fg,
	"setup leaves previous integrations visible"
)
h.eq({}, h.highlight("CmpItemAbbrMatch"), "setup does not apply newly enabled integration")

local setup_while_loaded = engine._snapshot_state()
h.eq(false, setup_while_loaded.baseline_applied, "setup snapshot baseline marker")
assert_snapshot_restoration(setup_while_loaded, "gruber-dark", function()
	return replacement_calls
end, "setup-while-loaded")
h.eq("typeset-paper", engine._state().configured_theme, "restore preserves replacement baseline")
h.eq(
	themes.get("typeset-paper").surface.base,
	engine.palette().surface.base,
	"restore public setup palette"
)
h.falsy(h.highlight("NeothemeKeyword").bold, "restore old applied options")
h.eq({}, h.highlight("CmpItemAbbrMatch"), "restore old applied integrations")
local replacement_calls_before_reset = replacement_calls
h.eq("typeset-paper", engine.reset(), "setup snapshot reset return")
h.eq(
	replacement_calls_before_reset + 1,
	replacement_calls,
	"setup snapshot marker forces reset apply"
)
h.eq(true, engine._snapshot_state().baseline_applied, "reset marks replacement baseline applied")
h.eq("typeset-paper", engine.current().active_theme, "reset applies replacement baseline")

local custom_reference = themes.get("ferric-forge")
local custom_calls = 0
engine.setup({
	theme = "custom",
	configure_palette = function(palette)
		custom_calls = custom_calls + 1
		for category, values in pairs(custom_reference) do
			for field, color in pairs(values) do
				if palette[category][field] == nil then
					palette[category][field] = color
				end
			end
		end
	end,
})
engine.load()
h.eq(1, custom_calls, "custom configured palette is reused by load")
local custom_snapshot = engine._snapshot_state()
h.eq("custom", custom_snapshot.applied_theme, "custom snapshot theme")
h.eq(nil, custom_snapshot.override_theme, "custom snapshot override")
h.eq(true, custom_snapshot.baseline_applied, "custom snapshot baseline marker")
local custom_calls_before_preview = custom_calls
engine.switch("gruber-light")
h.eq(custom_calls_before_preview + 1, custom_calls, "custom preview configurator")
h.eq("gruber-light", engine._state().override_theme, "configured custom retains built-in override")
local custom_calls_before_restore = custom_calls
engine._restore_state(custom_snapshot)
h.eq(custom_calls_before_restore, custom_calls, "custom restore must not rerun configurator")
h.eq(custom_snapshot, engine._snapshot_state(), "custom exact state restoration")
h.eq(
	h.color(custom_snapshot.applied_palette.surface.base),
	h.highlight("Normal").bg,
	"custom applied palette restoration"
)
h.eq("custom", engine._state().active_theme, "custom active theme restored")
h.eq(custom_reference, engine.palette(), "custom public palette restored")

local cache_calls = 0
local cache_accents = { "#e06b63", "#93c476", "#6aa9e9" }
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		cache_calls = cache_calls + 1
		palette.ui.accent = cache_accents[cache_calls]
	end,
})
engine.load()
h.eq(1, cache_calls, "cache regression setup is reused by load")
local cache_entry = engine._snapshot_state()
local entry_accent = cache_entry.configured_palette.ui.accent
h.eq(cache_accents[1], entry_accent, "entry configured cache accent")

engine.switch("gruber-light")
engine.switch("gruber-dark")
h.eq(3, cache_calls, "configured preview refreshes hidden cache")
h.eq(cache_accents[3], engine.palette().ui.accent, "configured preview palette")

engine._restore_state(cache_entry)
h.eq(3, cache_calls, "cache restore does not rerun configurator")
h.eq(entry_accent, engine.palette().ui.accent, "cache restore public palette")
h.eq(entry_accent, engine._snapshot_state().configured_palette.ui.accent, "cache restored exactly")

vim.cmd.colorscheme("default")
engine.load()
h.eq(3, cache_calls, "later load reuses restored entry cache")
h.eq(entry_accent, engine.palette().ui.accent, "later load ignores cancelled preview cache")
h.eq(h.color(entry_accent), h.highlight("Title").fg, "later load applies restored cache")
