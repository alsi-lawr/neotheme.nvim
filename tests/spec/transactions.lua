local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local config = require("neotheme.config")
local engine = require("neotheme")
local themes = require("neotheme.themes")

local function visible_contract()
	return {
		current = engine.current(),
		config = config.get(),
		palette = engine.palette(),
		background = vim.o.background,
		colors_name = vim.g.colors_name,
		normal = h.highlight("Normal"),
		keyword = h.highlight("NeothemeKeyword"),
		telescope = h.highlight("TelescopeMatching"),
		cmp = h.highlight("CmpItemAbbrMatch"),
		terminal_background = vim.g.terminal_color_background,
	}
end

engine.switch("gruber-light")
local preconfigured_snapshot = engine._snapshot_state()
h.eq(
	nil,
	preconfigured_snapshot.configured_palette,
	"pre-setup snapshot allows no configured cache"
)
engine.switch("typeset-ink")
engine._restore_state(preconfigured_snapshot)
h.eq(preconfigured_snapshot, engine._snapshot_state(), "pre-setup snapshot restores exactly")

vim.cmd.colorscheme("default")
local baseline_calls = 0
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		baseline_calls = baseline_calls + 1
		palette.ui.search = palette.diagnostic.error
	end,
	bold = false,
	integrations = { telescope = true },
})
engine.load()
h.eq(1, baseline_calls, "load reuses the configured cache")
local configured_snapshot = engine._snapshot_state()
local configured_visible = visible_contract()

engine.switch("gruber-light")
h.eq(2, baseline_calls, "preview switch resolves once")
engine._restore_state(configured_snapshot)
h.eq(2, baseline_calls, "snapshot restoration does not rerun configuration")
h.eq(configured_snapshot, engine._snapshot_state(), "configured snapshot restores exactly")
h.eq(configured_visible, visible_contract(), "configured snapshot restores visible state")

engine.switch("typeset-paper")
local override_snapshot = engine._snapshot_state()
engine.switch("typewriter-carbon")
engine._restore_state(override_snapshot)
h.eq(override_snapshot, engine._snapshot_state(), "override snapshot restores exactly")
h.eq("typeset-paper", engine.current().active_theme, "override snapshot restores selected theme")
h.eq(true, engine.current().session_override, "override snapshot restores override semantics")

local before_failed_setup = visible_contract()
local failed_ok, failed_error = pcall(engine.setup, {
	theme = "typeset-paper",
	configure_palette = function()
		error("intentional setup failure")
	end,
})
h.falsy(failed_ok, "failed setup is surfaced")
h.truthy(tostring(failed_error):find("intentional setup failure", 1, true), "setup failure cause")
h.eq(before_failed_setup, visible_contract(), "failed setup is state-atomic")

local old_normal = h.highlight("Normal")
engine.setup({
	theme = "typeset-paper",
	bold = true,
	integrations = { cmp = true },
})
h.eq("typeset-paper", engine.current().configured_theme, "setup replaces the baseline")
h.eq(
	themes.get("typeset-paper").surface.base,
	engine.palette().surface.base,
	"setup exposes the new palette"
)
h.eq(old_normal, h.highlight("Normal"), "setup does not change the visible colorscheme")
h.eq({}, h.highlight("CmpItemAbbrMatch"), "setup does not apply new integrations")
h.eq(false, engine._snapshot_state().baseline_applied, "setup marks the baseline unapplied")

engine.reset()
h.eq("typeset-paper", engine.current().active_theme, "reset applies the replacement baseline")
h.truthy(h.group_exists("CmpItemAbbrMatch"), "reset applies replacement integrations")
h.eq(true, engine._snapshot_state().baseline_applied, "reset marks the baseline applied")

local cache_calls = 0
local accents = { "#e06b63", "#93c476", "#6aa9e9" }
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		cache_calls = cache_calls + 1
		palette.ui.accent = accents[cache_calls]
	end,
})
engine.load()
local cache_snapshot = engine._snapshot_state()
local entry_accent = engine.palette().ui.accent
engine.switch("gruber-light")
engine.switch("gruber-dark")
h.eq(3, cache_calls, "switches refresh the configured palette cache")
h.eq(accents[3], engine.palette().ui.accent, "latest switch exposes its resolved palette")

engine._restore_state(cache_snapshot)
h.eq(3, cache_calls, "cache restoration does not rerun configuration")
h.eq(entry_accent, engine.palette().ui.accent, "cache restoration reinstates the entry palette")
vim.cmd.colorscheme("default")
engine.load()
h.eq(3, cache_calls, "later load reuses the restored cache")
h.eq(entry_accent, engine.palette().ui.accent, "cancelled preview cache does not leak")
h.eq(h.color(entry_accent), h.highlight("Title").fg, "restored cache reaches highlights")

local invalid_ok, invalid_error = pcall(engine._restore_state, { loaded = false })
h.falsy(invalid_ok, "unloaded snapshots are rejected")
h.truthy(tostring(invalid_error):find("cannot restore", 1, true), "invalid snapshot error")
