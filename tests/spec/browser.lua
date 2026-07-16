local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local browser = require("neotheme.browser")
local config = require("neotheme.config")
local engine = require("neotheme")

local function sorted_ids(values)
	local result = {}
	for _, value in ipairs(values) do
		table.insert(result, type(value) == "number" and value or value.id)
	end
	table.sort(result)
	return result
end

local function resources()
	return {
		windows = sorted_ids(vim.api.nvim_list_wins()),
		buffers = sorted_ids(vim.api.nvim_list_bufs()),
		current_window = vim.api.nvim_get_current_win(),
		current_buffer = vim.api.nvim_get_current_buf(),
	}
end

local function global_contract()
	return {
		current = engine.current(),
		config = config.get(),
		palette = engine.palette(),
		background = vim.o.background,
		colors_name = vim.g.colors_name,
		normal = h.highlight("Normal"),
		keyword = h.highlight("NeothemeKeyword"),
		telescope = h.highlight("TelescopeMatching"),
		terminal_background = vim.g.terminal_color_background,
		terminal_foreground = vim.g.terminal_color_foreground,
	}
end

local function browser_autocmds()
	local ok, definitions = pcall(vim.api.nvim_get_autocmds, { group = "NeothemeBrowser" })
	return ok and definitions or {}
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
		vim.wait(300, function()
			return browser._state() == nil
		end, 5),
		"browser close"
	)
end

local function geometry(window)
	local window_config = vim.api.nvim_win_get_config(window)
	return {
		row = window_config.row,
		col = window_config.col,
		width = window_config.width,
		height = window_config.height,
	}
end

local function title(window)
	local result = ""
	for _, chunk in ipairs(vim.api.nvim_win_get_config(window).title) do
		result = result .. chunk[1]
	end
	return result
end

local function assert_highlight_colors(expected, actual, label)
	h.eq(expected.fg, actual.fg, label .. " foreground")
	h.eq(expected.bg, actual.bg, label .. " background")
end

local function assert_clean(expected_resources, label)
	h.eq(nil, browser._state(), label .. " clears active state")
	h.eq(expected_resources, resources(), label .. " restores resources")
	h.eq(0, #browser_autocmds(), label .. " removes lifecycle autocmds")
end

local compact, compact_error = browser._layout(64, 18, 24)
h.eq(nil, compact_error, "minimum browser size is accepted")
h.truthy(compact.list.width > 0 and compact.preview.width > 0, "minimum panes have space")
h.eq(nil, browser._layout(63, 18, 24), "narrow editors are rejected")
h.eq(nil, browser._layout(64, 17, 24), "short editors are rejected")

h.eq(0, vim.fn.exists(":Neotheme"), "browser command starts unregistered")
engine._register_commands()
engine._register_commands()
h.eq(2, vim.fn.exists(":Neotheme"), "browser command registration is idempotent")
local invalid_resources = resources()
local invalid_ok, invalid_error = pcall(vim.api.nvim_exec2, "Neotheme surplus", { output = true })
h.falsy(invalid_ok, "browser command rejects arguments")
h.truthy(tostring(invalid_error):find("accepts no arguments", 1, true), "browser argument error")
h.eq(invalid_resources, resources(), "invalid command is resource-atomic")

local unloaded_resources = resources()
local unloaded_ok, unloaded_error = pcall(browser.open)
h.falsy(unloaded_ok, "browser requires a loaded theme")
h.truthy(tostring(unloaded_error):find("requires Neotheme to be loaded", 1, true), "unloaded error")
h.eq(unloaded_resources, resources(), "unloaded entry is resource-atomic")

local configure_calls = 0
engine.setup({
	theme = "gruber-dark",
	motion = "reduced",
	configure_palette = function(palette)
		configure_calls = configure_calls + 1
		palette.ui.search = palette.diagnostic.error
	end,
	bold = false,
	italic = { strings = false },
	integrations = { telescope = true },
})
engine.load()
h.eq(1, configure_calls, "fixture palette resolves once")

local entry_contract = global_contract()
local entry_resources = resources()
local origin_window = vim.api.nvim_get_current_win()
local cached_discovered_lualine = require("lualine.themes.neotheme")
local cached_lualine = require("neotheme.lualine")
browser.open()
local state = assert(browser._state())
h.eq("families", state.mode, "browser opens at family selection")
h.eq("gruber", state.families[state.selected_family_index], "active family is selected")
h.eq("gruber-dark", state.last_previewed_theme, "active theme seeds the preview")
h.eq(state.list_window, vim.api.nvim_get_current_win(), "selector receives focus")
h.eq(origin_window, state.origin_window, "origin window is retained")

local preview_normal = vim.api.nvim_get_hl(state.preview_namespace, { name = "Normal" })
assert_highlight_colors(h.highlight("Normal"), preview_normal, "initial preview")
h.eq("lua", vim.bo[state.preview_buffer].filetype, "preview uses Lua highlighting")
h.eq(4, #vim.diagnostic.get(state.preview_buffer, {
	namespace = state.diagnostic_namespace,
}), "preview includes diagnostic examples")
h.truthy(title(state.list_window):find("Neotheme · Families", 1, true), "family selector title")
h.truthy(title(state.preview_window):find("Preview · gruber-dark", 1, true), "preview title")
h.truthy(#browser_autocmds() >= 6, "browser installs lifecycle autocmds")

vim.api.nvim_set_current_win(origin_window)
browser.open()
h.eq(state.list_window, vim.api.nvim_get_current_win(), "duplicate open focuses existing selector")
h.eq(state.list_window, browser._state().list_window, "duplicate open keeps one browser")

move_to("typeset")
h.eq(
	"typeset",
	state.families[browser._state().selected_family_index],
	"family navigation updates selection"
)
h.eq(1, configure_calls, "family navigation does not prepare a preview")
h.eq(entry_contract, global_contract(), "family navigation preserves global theme state")

press("<CR>")
local themes_state = assert(browser._state())
h.eq("themes", themes_state.mode, "Enter drills into the selected family")
h.eq("typeset-ink", themes_state.last_previewed_theme, "family drill previews its first theme")
h.eq(2, configure_calls, "family drill prepares one local preview")
h.eq(entry_contract, global_contract(), "family drill remains preview-only")
h.truthy(package.loaded["neotheme.lualine"] == cached_lualine, "preview preserves Lualine cache")
h.truthy(
	package.loaded["lualine.themes.neotheme"] == cached_discovered_lualine,
	"preview preserves discovered Lualine cache"
)
h.eq(
	{},
	vim.api.nvim_get_hl(themes_state.preview_namespace, { name = "TelescopeMatching" }),
	"preview excludes integrations"
)
h.eq(
	h.color(themes_state.preview_palette.surface.base),
	vim.api.nvim_get_hl(themes_state.preview_namespace, { name = "Normal" }).bg,
	"preview palette is visible only in the preview namespace"
)

move_to("typeset-paper")
local paper_state = assert(browser._state())
h.eq("typeset-paper", paper_state.last_previewed_theme, "theme navigation updates the preview")
h.eq(3, configure_calls, "theme navigation prepares once")
h.eq(entry_contract, global_contract(), "theme navigation preserves global theme state")
h.truthy(
	title(paper_state.preview_window):find("Preview · typeset-paper", 1, true),
	"preview metadata follows selection"
)

local original_layout = browser._layout
local resized_layout =
	assert(original_layout(vim.o.columns - 6, vim.o.lines - vim.o.cmdheight - 2, 24))
browser._layout = function()
	return resized_layout
end
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
browser._layout = original_layout
h.eq(resized_layout, browser._state().layout, "resize updates browser layout")
h.eq(resized_layout.list, geometry(state.list_window), "resize updates selector geometry")
h.eq(resized_layout.preview, geometry(state.preview_window), "resize updates preview geometry")

press("<Space>")
local checkpoint_state = assert(browser._state())
h.eq("typeset-paper", engine.current().active_theme, "Space applies the selected theme")
h.eq(true, engine.current().session_override, "Space creates only a session override")
h.eq("themes", checkpoint_state.mode, "Space leaves the browser open")
h.eq(
	true,
	checkpoint_state.preview_matches_checkpoint,
	"Space advances the cancellation checkpoint"
)
local checkpoint_contract = global_contract()

move_to("typeset-ink")
h.eq(checkpoint_contract, global_contract(), "movement after Space remains preview-only")
close("q")
h.eq(checkpoint_contract, global_contract(), "q preserves the latest confirmed theme")
assert_clean(entry_resources, "q cancellation")

local enter_resources = resources()
browser.open()
local enter_state = assert(browser._state())
press("<CR>")
move_to("typeset-ink")
close("<CR>")
h.eq("typeset-ink", engine.current().active_theme, "Enter applies the selected theme")
h.eq(true, engine.current().session_override, "Enter remains session-only")
assert_clean(enter_resources, "Enter acceptance")

local sentinel = { fg = 0x65a9e8, bold = true }
vim.api.nvim_set_hl(0, "NeothemeBrowserSentinel", sentinel)
local preview_cancel_resources = resources()
browser.open()
move_to("arcfield")
press("<CR>")
close("q")
local preserved_sentinel = h.highlight("NeothemeBrowserSentinel")
h.eq(sentinel.fg, preserved_sentinel.fg, "preview cancellation preserves unrelated color")
h.eq(sentinel.bold, preserved_sentinel.bold, "preview cancellation preserves unrelated style")
assert_clean(preview_cancel_resources, "preview-only q cancellation")

local undersized_contract = global_contract()
local undersized_resources = resources()
browser.open()
local undersized_state = assert(browser._state())
move_to("arcfield")
press("<CR>")
local notifications = {}
local original_notify = vim.notify
vim.notify = function(message, level)
	table.insert(notifications, { message = message, level = level })
end
browser._layout = function()
	return nil, "neotheme: deliberate undersized resize"
end
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
browser._layout = original_layout
vim.notify = original_notify
h.eq(undersized_contract, global_contract(), "undersized resize restores the checkpoint")
h.eq(1, #notifications, "undersized resize reports once")
h.truthy(
	notifications[1].message:find("deliberate undersized resize", 1, true),
	"resize failure cause"
)
h.falsy(vim.api.nvim_win_is_valid(undersized_state.list_window), "resize failure closes selector")
assert_clean(undersized_resources, "undersized resize")

local lifecycle_contract = global_contract()
local lifecycle_resources = resources()
browser.open()
local lifecycle_state = assert(browser._state())
move_to("typeset")
press("<CR>")
vim.api.nvim_win_close(lifecycle_state.list_window, true)
h.eq(lifecycle_contract, global_contract(), "surface closure restores the checkpoint")
assert_clean(lifecycle_resources, "surface closure")

local creation_contract = global_contract()
local creation_resources = resources()
local original_open_win = vim.api.nvim_open_win
local open_calls = 0
vim.api.nvim_open_win = function(...)
	open_calls = open_calls + 1
	if open_calls == 2 then
		error("intentional partial window creation failure")
	end
	return original_open_win(...)
end
local creation_ok, creation_error = pcall(browser.open)
vim.api.nvim_open_win = original_open_win
h.falsy(creation_ok, "partial window creation failure is surfaced")
h.truthy(
	tostring(creation_error):find("partial window creation failure", 1, true),
	"creation failure cause"
)
h.eq(creation_contract, global_contract(), "creation failure preserves global state")
assert_clean(creation_resources, "creation failure")

local preview_contract = global_contract()
local preview_resources = resources()
browser.open()
move_to("arcfield")
local original_prepare_preview = engine._prepare_preview
engine._prepare_preview = function()
	error("intentional preview preparation failure")
end
notifications = {}
original_notify = vim.notify
vim.notify = function(message, level)
	table.insert(notifications, { message = message, level = level })
end
press("<CR>")
engine._prepare_preview = original_prepare_preview
vim.notify = original_notify
h.eq(preview_contract, global_contract(), "preview failure restores global state")
h.eq(1, #notifications, "preview failure reports once")
h.truthy(
	notifications[1].message:find("preview preparation failure", 1, true),
	"preview failure cause"
)
assert_clean(preview_resources, "preview failure")
