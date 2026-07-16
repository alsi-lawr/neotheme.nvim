local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local browser = require("neotheme.browser")
local config = require("neotheme.config")
local engine = require("neotheme")

local function global_state()
	return {
		current = engine.current(),
		snapshot = engine._snapshot_state(),
		config = config.get(),
		palette = engine.palette(),
		background = vim.o.background,
		colors_name = vim.g.colors_name,
		normal = h.highlight("Normal"),
		keyword = h.highlight("NeothemeKeyword"),
		telescope = h.highlight("TelescopeMatching"),
		terminal_0 = vim.g.terminal_color_0,
		terminal_15 = vim.g.terminal_color_15,
		terminal_background = vim.g.terminal_color_background,
		terminal_foreground = vim.g.terminal_color_foreground,
	}
end

local function entries(state)
	if state.mode == "families" then
		return state.families
	end
	local family = state.families[state.selected_family_index]
	return state.themes_by_family[family]
end

local function index_of(values, expected)
	for index, value in ipairs(values) do
		if value == expected then
			return index
		end
	end
	error("missing browser entry: " .. expected)
end

local function move_to(name)
	local state = assert(browser._state())
	local index = index_of(entries(state), name)
	vim.api.nvim_set_current_win(state.list_window)
	vim.api.nvim_win_set_cursor(state.list_window, { index + 1, 0 })
	vim.api.nvim_exec_autocmds("CursorMoved", {
		buffer = state.list_buffer,
		modeline = false,
	})
	return assert(browser._state())
end

local function press(key)
	vim.api.nvim_feedkeys(vim.keycode(key), "x", false)
end

local function wait_for_transition()
	h.truthy(
		vim.wait(500, function()
			local state = browser._state()
			return state == nil or not state.transitioning
		end, 5),
		"preview transition completion"
	)
end

local function close(key)
	press(key)
	h.truthy(
		vim.wait(300, function()
			return browser._state() == nil
		end, 5),
		"browser close"
	)
end

local midpoint = browser._interpolate_palette(
	{ surface = { base = "#000000" } },
	{ surface = { base = "#ffffff" } },
	0.5
)
h.eq("#808080", midpoint.surface.base, "RGB midpoint interpolation")
h.eq(
	"#000000",
	browser._interpolate_palette(
		{ surface = { base = "#000000" } },
		{ surface = { base = "#ffffff" } },
		-1
	).surface.base,
	"interpolation clamps the lower bound"
)
h.eq(
	"#ffffff",
	browser._interpolate_palette(
		{ surface = { base = "#000000" } },
		{ surface = { base = "#ffffff" } },
		2
	).surface.base,
	"interpolation clamps the upper bound"
)

local configure_calls = 0
engine.setup({
	theme = "gruber-dark",
	motion = "interpolate",
	configure_palette = function(palette)
		configure_calls = configure_calls + 1
		palette.ui.search = palette.diagnostic.warning
	end,
	integrations = { telescope = true },
})
engine.load()
h.eq(1, configure_calls, "interpolation fixture reuses setup palette")

local interpolation_entry = global_state()
local cached_discovered_lualine = require("lualine.themes.neotheme")
local cached_lualine = require("neotheme.lualine")
browser.open()
local interpolation_state = assert(browser._state())
h.eq("interpolate", interpolation_state.motion, "interpolation policy")
move_to("typeset")
press("<Space>")
h.eq("themes", browser._state().mode, "Space drills into a family")
h.eq(interpolation_entry, global_state(), "family Space and first preview preserve global state")
h.eq(2, configure_calls, "first local preview resolves once")

local first_transition = assert(browser._state())
h.eq("typeset-ink", first_transition.last_previewed_theme, "first interpolation target")
h.truthy(first_transition.transitioning, "interpolation begins immediately")
h.falsy(
	vim.deep_equal(first_transition.rendered_palette, interpolation_entry.palette),
	"first interpolation frame advances from the source"
)
h.falsy(
	vim.deep_equal(first_transition.rendered_palette, first_transition.preview_palette),
	"first interpolation frame is not the final palette"
)

local generation = first_transition.transition_generation
local intermediate = vim.deepcopy(first_transition.rendered_palette)
move_to("typeset-paper")
local restarted = assert(browser._state())
h.truthy(restarted.transition_generation > generation, "new selection cancels the prior transition")
h.eq("typeset-paper", restarted.last_previewed_theme, "rapid navigation replaces the target")
h.falsy(
	vim.deep_equal(restarted.rendered_palette, intermediate),
	"replacement interpolation advances from the rendered intermediate palette"
)

local layout_before_resize = restarted.layout
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
h.truthy(browser._state() ~= nil, "resize preserves an active transition")
h.eq(layout_before_resize, browser._state().layout, "resize recomputes stable geometry")

wait_for_transition()
local interpolated = assert(browser._state())
h.eq(interpolated.preview_palette, interpolated.rendered_palette, "interpolation reaches target")
h.eq(
	h.color(interpolated.preview_palette.surface.base),
	vim.api.nvim_get_hl(interpolated.preview_namespace, { name = "Normal" }).bg,
	"interpolated target reaches the preview namespace"
)
h.eq(interpolation_entry, global_state(), "completed interpolation remains preview-only")
h.truthy(package.loaded["neotheme.lualine"] == cached_lualine, "preview preserves Lualine cache")
h.truthy(
	package.loaded["lualine.themes.neotheme"] == cached_discovered_lualine,
	"preview preserves discovered Lualine cache"
)

press("<Space>")
local confirmed = assert(browser._state())
h.eq("typeset-paper", engine.current().active_theme, "Space confirms globally")
h.eq(true, engine.current().session_override, "Space creates a session override")
h.eq("themes", confirmed.mode, "Space keeps the browser open")
h.eq(true, confirmed.preview_matches_checkpoint, "Space advances the checkpoint")
h.eq(0, vim.wo[confirmed.preview_window].winblend, "Space leaves the preview opaque")
local checkpoint = global_state()

move_to("typeset-ink")
wait_for_transition()
h.eq(checkpoint, global_state(), "post-Space movement remains local")
local restore_calls = 0
local original_restore = engine._restore_state
engine._restore_state = function(snapshot)
	restore_calls = restore_calls + 1
	return original_restore(snapshot)
end
close("q")
engine._restore_state = original_restore
h.eq(1, restore_calls, "q restores the latest Space checkpoint once")
h.eq(checkpoint, global_state(), "q preserves the latest confirmed theme")

engine.setup({ theme = "typeset-paper", motion = "winblend" })
engine.load()
local winblend_entry = global_state()
browser.open()
press("<CR>")
move_to("typeset-ink")
local fading = assert(browser._state())
h.eq("winblend", fading.motion, "winblend policy")
h.truthy(fading.transitioning, "winblend fade begins")
h.truthy(vim.wo[fading.preview_window].winblend > 0, "winblend fade changes preview opacity")
h.eq(fading.preview_palette, fading.rendered_palette, "winblend applies target colors immediately")
h.eq(0, vim.wo[fading.list_window].winblend, "winblend leaves selector opaque")
h.eq(60, vim.wo[fading.backdrop_window].winblend, "winblend leaves backdrop unchanged")
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
h.truthy(browser._state() ~= nil, "resize preserves winblend transition")
wait_for_transition()
h.eq(0, vim.wo[browser._state().preview_window].winblend, "winblend fade returns to opaque")
h.eq(winblend_entry, global_state(), "winblend remains preview-only")
close("<Esc>")

engine.setup({ theme = "typeset-paper", motion = "reduced" })
engine.load()
local reduced_entry = global_state()
browser.open()
press("<CR>")
move_to("typeset-ink")
local reduced = assert(browser._state())
h.eq("reduced", reduced.motion, "reduced-motion policy")
h.eq(false, reduced.transitioning, "reduced motion has no deferred transition")
h.eq(reduced.preview_palette, reduced.rendered_palette, "reduced motion applies target immediately")
h.eq(0, vim.wo[reduced.preview_window].winblend, "reduced motion never changes opacity")
h.eq(reduced_entry, global_state(), "reduced motion remains preview-only")
close("<Esc>")

engine.setup({ theme = "gruber-dark", motion = "reduced" })
engine.load()
local confirmation_entry = global_state()
browser.open()
move_to("typeset")
press("<CR>")
local notifications = {}
local original_notify = vim.notify
local original_switch = engine.switch
local failed_switches = 0
engine.switch = function()
	failed_switches = failed_switches + 1
	vim.o.background = "light"
	error("intentional partial confirmation failure " .. failed_switches)
end
vim.notify = function(message, level)
	table.insert(notifications, { message = message, level = level })
end
press("<Space>")
h.eq(confirmation_entry, global_state(), "first failed confirmation restores the checkpoint")
press("<Space>")
engine.switch = original_switch
vim.notify = original_notify
h.truthy(browser._state() ~= nil, "failed confirmation keeps the browser available")
h.eq(confirmation_entry, global_state(), "repeated failed confirmation restores the checkpoint")
h.eq(2, #notifications, "each failed confirmation reports once")
h.truthy(
	notifications[1].message:find("intentional partial confirmation failure 1", 1, true),
	"first failed confirmation reports its cause"
)
h.truthy(
	notifications[2].message:find("intentional partial confirmation failure 2", 1, true),
	"second failed confirmation reports its cause"
)
close("q")
h.eq(confirmation_entry, global_state(), "q preserves the checkpoint after repeated failures")

engine.setup({ theme = "gruber-dark", motion = "interpolate" })
engine.load()
local close_during_transition_entry = global_state()
browser.open()
move_to("typeset")
press("<CR>")
h.truthy(browser._state().transitioning, "final interpolation starts")
close("q")
vim.wait(200, function()
	return false
end, 20)
h.eq(nil, browser._state(), "stale callbacks do not reopen the browser")
h.eq(close_during_transition_entry, global_state(), "stale callbacks preserve global state")
