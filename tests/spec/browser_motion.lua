local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local browser = require("neotheme.browser")
local config = require("neotheme.config")
local engine = require("neotheme")

local function global_contract()
	return {
		current = engine.current(),
		config = config.get(),
		palette = engine.palette(),
		background = vim.o.background,
		colors_name = vim.g.colors_name,
		normal = h.highlight("Normal"),
		telescope = h.highlight("TelescopeMatching"),
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

local function close(key)
	press(key)
	h.truthy(
		vim.wait(500, function()
			return browser._state() == nil
		end, 5),
		"browser close"
	)
end

local function wait_for_transition()
	h.truthy(
		vim.wait(800, function()
			local state = browser._state()
			return state == nil or not state.transitioning
		end, 5),
		"preview transition completion"
	)
end

h.eq(
	"#808080",
	browser._interpolate_palette(
		{ surface = { base = "#000000" } },
		{ surface = { base = "#ffffff" } },
		0.5
	).surface.base,
	"RGB interpolation midpoint"
)

engine.setup({
	theme = "gruber-dark",
	motion = "interpolate",
	integrations = { telescope = true },
})
engine.load()
local interpolation_entry = global_contract()
browser.open()
move_to("typeset")
press("<CR>")
local interpolating = assert(browser._state())
h.eq("interpolate", interpolating.motion, "interpolation policy")
h.eq("typeset-ink", interpolating.last_previewed_theme, "same-polarity target")
h.truthy(interpolating.transitioning, "same-polarity transition begins")
h.falsy(
	vim.deep_equal(interpolating.rendered_palette, interpolating.preview_palette),
	"same-polarity transition renders an intermediate frame"
)
h.eq(interpolation_entry, global_contract(), "interpolation remains preview-only")

local generation = interpolating.transition_generation
move_to("typeset-paper")
local fading = assert(browser._state())
h.truthy(fading.transition_generation > generation, "new selection cancels the old transition")
h.eq("light", fading.preview_background, "cross-polarity target records its background")
h.truthy(fading.transitioning, "cross-polarity interpolation begins")
h.falsy(
	vim.deep_equal(fading.preview_palette, fading.rendered_palette),
	"cross-polarity interpolation renders a transition frame"
)
h.eq(0, vim.wo[fading.preview_window].winblend, "interpolation remains opaque")
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
h.truthy(browser._state() ~= nil, "resize preserves an active transition")
wait_for_transition()
local completed = assert(browser._state())
h.eq(0, vim.wo[completed.preview_window].winblend, "fade returns to an opaque surface")
h.eq(
	h.color(completed.preview_palette.surface.base),
	vim.api.nvim_get_hl(completed.preview_namespace, { name = "Normal" }).bg,
	"target palette reaches the preview namespace"
)
h.eq(interpolation_entry, global_contract(), "completed transition remains preview-only")
close("q")

engine.setup({ theme = "typeset-paper", motion = "winblend" })
engine.load()
local winblend_entry = global_contract()
browser.open()
press("<CR>")
move_to("typeset-ink")
local winblend = assert(browser._state())
h.eq("winblend", winblend.motion, "winblend policy")
h.truthy(winblend.transitioning, "winblend transition begins")
h.eq(
	winblend.preview_palette,
	winblend.rendered_palette,
	"winblend applies target colors immediately"
)
h.truthy(vim.wo[winblend.preview_window].winblend >= 40, "winblend transition is visible")
wait_for_transition()
h.eq(0, vim.wo[browser._state().preview_window].winblend, "winblend returns to opaque")
h.eq(winblend_entry, global_contract(), "winblend remains preview-only")
close("<Esc>")

engine.setup({ theme = "typeset-paper", motion = "reduced" })
engine.load()
local reduced_entry = global_contract()
browser.open()
press("<CR>")
local before_swap = assert(browser._state())
local visible_namespace = before_swap.preview_namespace
local wrote_visible_namespace = false
local original_set_hl = vim.api.nvim_set_hl
vim.api.nvim_set_hl = function(namespace, name, highlight)
	if namespace == visible_namespace then
		wrote_visible_namespace = true
	end
	return original_set_hl(namespace, name, highlight)
end
move_to("typeset-ink")
vim.api.nvim_set_hl = original_set_hl
local reduced = assert(browser._state())
h.eq("reduced", reduced.motion, "reduced-motion policy")
h.falsy(reduced.transitioning, "reduced motion has no deferred work")
h.falsy(wrote_visible_namespace, "preview frame is built off-screen")
h.falsy(
	reduced.preview_namespace == visible_namespace,
	"completed frame atomically swaps namespaces"
)
h.eq(reduced.preview_palette, reduced.rendered_palette, "reduced motion applies target immediately")
h.eq(reduced_entry, global_contract(), "reduced motion remains preview-only")
close("q")

engine.setup({ theme = "gruber-dark", motion = "reduced" })
engine.load()
local confirmation_entry = global_contract()
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
h.eq(confirmation_entry, global_contract(), "first partial failure restores the checkpoint")
h.eq(1, #notifications, "first failed confirmation reports once")
press("<Space>")
engine.switch = original_switch
vim.notify = original_notify
h.truthy(browser._state() ~= nil, "failed confirmation keeps the browser available")
h.eq(confirmation_entry, global_contract(), "repeated partial failures restore the checkpoint")
h.eq(2, #notifications, "each failed confirmation reports once")
close("q")
h.eq(confirmation_entry, global_contract(), "q preserves the checkpoint after failures")

engine.setup({
	theme = "gruber-dark",
	motion = "reduced",
	integrations = { cmp = false },
})
engine.load()
engine.setup({
	theme = "gruber-dark",
	motion = "reduced",
	integrations = { cmp = true },
})
browser.open()
move_to("typeset")
press("<CR>")
original_switch = engine.switch
original_notify = vim.notify
engine.switch = function()
	vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { fg = 0xff00ff })
	error("intentional partial integration failure")
end
vim.notify = function() end
press("<Space>")
engine.switch = original_switch
vim.notify = original_notify
h.eq({}, h.highlight("CmpItemAbbrMatch"), "rollback clears partially applied integrations")
h.eq("gruber-dark", engine.current().active_theme, "integration failure restores active theme")
h.truthy(browser._state() ~= nil, "integration failure keeps the browser available")
h.eq(
	false,
	engine._snapshot_state().baseline_applied,
	"rollback retains the unapplied baseline marker"
)
close("q")
engine.reset()
h.truthy(h.group_exists("CmpItemAbbrMatch"), "reset applies the replacement integration baseline")

engine.setup({
	theme = "gruber-dark",
	motion = "reduced",
	integrations = { cmp = false },
})
engine.load()
browser.open()
move_to("typeset")
press("<CR>")
original_switch = engine.switch
original_notify = vim.notify
local original_restore = engine._restore_state
local restore_attempts = 0
engine.switch = function()
	error("intentional selection failure before nested rollback")
end
engine._restore_state = function(snapshot, force_clear)
	restore_attempts = restore_attempts + 1
	if restore_attempts == 1 then
		vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { fg = 0xff00ff })
		error("intentional first rollback failure")
	end
	return original_restore(snapshot, force_clear)
end
vim.notify = function() end
press("<Space>")
engine.switch = original_switch
engine._restore_state = original_restore
vim.notify = original_notify
h.eq(2, restore_attempts, "failed forced rollback is retried once")
h.eq(nil, browser._state(), "failed forced rollback closes the browser")
h.eq("gruber-dark", engine.current().active_theme, "nested rollback restores active theme")
h.eq({}, h.highlight("CmpItemAbbrMatch"), "nested rollback clears partial integrations")

engine.setup({ theme = "gruber-dark", motion = "interpolate" })
engine.load()
local interrupted_entry = global_contract()
browser.open()
move_to("typeset")
press("<CR>")
h.truthy(browser._state().transitioning, "interrupted transition starts")
close("q")
vim.wait(450, function()
	return false
end, 20)
h.eq(nil, browser._state(), "stale callbacks do not reopen the browser")
h.eq(interrupted_entry, global_contract(), "stale callbacks preserve global state")
