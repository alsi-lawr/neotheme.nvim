local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local browser = require("neotheme.browser")
local config = require("neotheme.config")
local engine = require("neotheme")
local themes = require("neotheme.themes")

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

local function browser_autocmds()
	local ok, definitions = pcall(vim.api.nvim_get_autocmds, { group = "NeothemeBrowser" })
	return ok and definitions or {}
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
	}
end

local function title(window)
	local chunks = vim.api.nvim_win_get_config(window).title
	local result = ""
	for _, chunk in ipairs(chunks) do
		result = result .. chunk[1]
	end
	return result
end

local function index_of(names, expected)
	for index, name in ipairs(names) do
		if name == expected then
			return index
		end
	end
	error("missing browser entry: " .. expected)
end

local function entries(state)
	if state.mode == "families" then
		return state.families
	end
	local family = state.families[state.selected_family_index]
	return state.themes_by_family[family]
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
	return browser._state()
end

local function press(key)
	vim.api.nvim_feedkeys(vim.keycode(key), "x", false)
end

local function press_and_close(key)
	press(key)
	h.truthy(
		vim.wait(200, function()
			return browser._state() == nil
		end, 5),
		"browser mapping cleanup"
	)
end

local function assert_clean(state, expected_resources, label)
	h.eq(nil, browser._state(), label .. " active state")
	h.eq(expected_resources, resources(), label .. " resources")
	h.eq(0, #browser_autocmds(), label .. " autocmds")
	for name, window in pairs({
		backdrop = state.backdrop_window,
		list = state.list_window,
		preview = state.preview_window,
	}) do
		h.falsy(vim.api.nvim_win_is_valid(window), label .. " " .. name .. " window")
	end
	for name, buffer in pairs({
		backdrop = state.backdrop_buffer,
		list = state.list_buffer,
		preview = state.preview_buffer,
	}) do
		h.falsy(vim.api.nvim_buf_is_valid(buffer), label .. " " .. name .. " buffer")
	end
	h.eq(
		{},
		vim.diagnostic.get(nil, { namespace = state.diagnostic_namespace }),
		label .. " diagnostics"
	)
end

local function with_restore_counter(action)
	local original_restore = engine._restore_state
	local count = 0
	engine._restore_state = function(snapshot)
		count = count + 1
		return original_restore(snapshot)
	end

	local ok, result = pcall(action)
	engine._restore_state = original_restore
	if not ok then
		error(result)
	end
	return count, result
end

local function fill_custom(palette)
	local reference = themes.get("ferric-forge")
	for category, values in pairs(reference) do
		for field, color in pairs(values) do
			palette[category][field] = color
		end
	end
end

local function highlight_link(name)
	return vim.api.nvim_get_hl(0, { name = name, link = true }).link
end

local function tab_marks(state)
	return vim.api.nvim_buf_get_extmarks(
		state.list_buffer,
		state.tab_namespace,
		{ 0, 0 },
		{ 0, -1 },
		{ details = true }
	)
end

local compact, compact_error = browser._layout(64, 18, 24)
h.eq(nil, compact_error, "minimum layout error")
h.eq({ row = 0, col = 0, width = 64, height = 18 }, compact.backdrop, "backdrop layout")
h.truthy(compact.list.width > 0, "minimum list width")
h.truthy(compact.preview.width > 0, "minimum preview width")
h.truthy(compact.list.row >= 2, "minimum top margin")
h.truthy(compact.list.col >= 2, "minimum left margin")
h.truthy(compact.preview.col >= compact.list.col + compact.list.width + 3, "layout gap")
h.truthy(compact.preview.col + compact.preview.width + 2 <= 64, "minimum right bound")
h.truthy(compact.preview.row + compact.preview.height + 2 <= 18, "minimum bottom bound")
h.eq(nil, browser._layout(63, 18, 24), "narrow layout rejection")
h.eq(nil, browser._layout(64, 17, 24), "short layout rejection")

h.eq(0, vim.fn.exists(":Neotheme"), "browser command absent under --noplugin")
engine._register_commands()
engine._register_commands()
h.eq(2, vim.fn.exists(":Neotheme"), "browser command registration is idempotent")
h.eq(2, vim.fn.exists(":NeothemeList"), "list command remains registered")
h.eq(2, vim.fn.exists(":NeothemeSwitch"), "switch command remains registered")
h.eq(2, vim.fn.exists(":NeothemeCurrent"), "current command remains registered")
h.eq(2, vim.fn.exists(":NeothemeReset"), "reset command remains registered")
h.eq(2, vim.fn.exists(":NeothemeReload"), "reload command remains registered")
h.eq({}, vim.fn.getcompletion("Neotheme ", "cmdline"), "browser command has no completion")

local original_open = browser.open
local browser_open_calls = 0
browser.open = function()
	browser_open_calls = browser_open_calls + 1
	return original_open()
end
local invalid_resources = resources()
local invalid_snapshot = engine._snapshot_state()
local invalid_ok, invalid_error = pcall(vim.api.nvim_exec2, "Neotheme surplus", {
	output = true,
})
browser.open = original_open
h.falsy(invalid_ok, "surplus browser arguments must fail")
h.truthy(tostring(invalid_error):find("accepts no arguments", 1, true), "browser argument error")
h.eq(0, browser_open_calls, "surplus arguments fail before browser entry")
h.eq(invalid_snapshot, engine._snapshot_state(), "surplus arguments preserve state")
h.eq(invalid_resources, resources(), "surplus arguments preserve resources")

local unloaded_resources = resources()
local unloaded_snapshot = engine._snapshot_state()
local original_families = engine.families
local inventory_calls = 0
engine.families = function(...)
	inventory_calls = inventory_calls + 1
	return original_families(...)
end
local unloaded_ok, unloaded_error = pcall(browser.open)
engine.families = original_families
h.falsy(unloaded_ok, "unloaded browser entry must fail")
h.truthy(tostring(unloaded_error):find("requires Neotheme to be loaded", 1, true), "unloaded error")
h.eq(0, inventory_calls, "unloaded entry fails before inventory")
h.eq(unloaded_snapshot, engine._snapshot_state(), "unloaded entry preserves state")
h.eq(unloaded_resources, resources(), "unloaded entry preserves resources")
h.eq(nil, browser._state(), "unloaded entry has no active browser")

local configured_calls = 0
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		configured_calls = configured_calls + 1
		palette.ui.search = palette.diagnostic.error
	end,
	bold = false,
	italic = { strings = false },
	underline = false,
	undercurl = false,
	integrations = { telescope = true, cmp = false },
})
engine.load()
h.eq(1, configured_calls, "browser fixture load reuses configured palette")

local external_entry = runtime_state()
vim.cmd.colorscheme("default")
local external_discovered = require("lualine.themes.neotheme")
local external_lualine = require("neotheme.lualine")
local external_state = {
	snapshot = engine._snapshot_state(),
	current = engine.current(),
	config = config.get(),
	resources = resources(),
	background = vim.o.background,
	colors_name = vim.g.colors_name,
	normal = h.highlight("Normal"),
	terminal_0 = vim.g.terminal_color_0,
	terminal_1 = vim.g.terminal_color_1,
	terminal_15 = vim.g.terminal_color_15,
	terminal_background = vim.g.terminal_color_background,
	terminal_foreground = vim.g.terminal_color_foreground,
}
local external_ok, external_error = pcall(browser.open)
h.falsy(external_ok, "external colorscheme browser entry must fail")
h.truthy(tostring(external_error):find("requires Neotheme to be loaded", 1, true), "external error")
h.eq(external_state.snapshot, engine._snapshot_state(), "external entry preserves snapshot")
h.eq(external_state.current, engine.current(), "external entry preserves current state")
h.eq(external_state.config, config.get(), "external entry preserves configuration")
h.eq(external_state.resources, resources(), "external entry preserves resources")
h.eq(external_state.background, vim.o.background, "external entry preserves background")
h.eq(external_state.colors_name, vim.g.colors_name, "external entry preserves colorscheme")
h.eq(external_state.normal, h.highlight("Normal"), "external entry preserves highlights")
h.eq(external_state.terminal_0, vim.g.terminal_color_0, "external entry terminal 0")
h.eq(external_state.terminal_1, vim.g.terminal_color_1, "external entry terminal 1")
h.eq(external_state.terminal_15, vim.g.terminal_color_15, "external entry terminal 15")
h.eq(external_state.terminal_background, vim.g.terminal_color_background, "external terminal bg")
h.eq(external_state.terminal_foreground, vim.g.terminal_color_foreground, "external terminal fg")
h.truthy(package.loaded["neotheme.lualine"] == external_lualine, "external Lualine cache")
h.truthy(
	package.loaded["lualine.themes.neotheme"] == external_discovered,
	"external discovered Lualine cache"
)
engine.load()
h.eq(1, configured_calls, "load after external entry reuses configured cache")
h.eq(external_entry.snapshot, engine._snapshot_state(), "load restores configured fixture")

local empty_snapshot_calls = 0
local original_snapshot = engine._snapshot_state
engine._snapshot_state = function()
	empty_snapshot_calls = empty_snapshot_calls + 1
	return original_snapshot()
end
engine.families = function()
	return {}
end
local empty_resources = resources()
local empty_ok, empty_error = pcall(browser.open)
engine.families = original_families
engine._snapshot_state = original_snapshot
h.falsy(empty_ok, "empty family inventory must fail")
h.truthy(tostring(empty_error):find("no built-in themes", 1, true), "empty inventory error")
h.eq(0, empty_snapshot_calls, "empty inventory fails before snapshot")
h.eq(empty_resources, resources(), "empty inventory preserves resources")

local layout_snapshot_calls = 0
local original_layout = browser._layout
engine._snapshot_state = function()
	layout_snapshot_calls = layout_snapshot_calls + 1
	return original_snapshot()
end
browser._layout = function()
	return nil, "neotheme: deliberate small layout"
end
local small_resources = resources()
local small_ok, small_error = pcall(browser.open)
browser._layout = original_layout
engine._snapshot_state = original_snapshot
h.falsy(small_ok, "small browser layout must fail")
h.truthy(tostring(small_error):find("deliberate small layout", 1, true), "small layout error")
h.eq(0, layout_snapshot_calls, "layout failure precedes snapshot")
h.eq(small_resources, resources(), "layout failure preserves resources")

local public_themes = engine.themes()
local public_families = engine.families()
local entry_state = runtime_state()
local entry_resources = resources()
local origin_window = vim.api.nvim_get_current_win()
browser.open()
local state = assert(browser._state())
h.eq("families", state.mode, "browser opens on families tab")
h.eq(state.list_window, vim.api.nvim_get_current_win(), "browser focuses selector")
h.eq(origin_window, state.origin_window, "browser captures origin")
h.eq(public_themes, engine.themes(), "browser does not mutate public themes")
h.eq(public_families, engine.families(), "browser does not mutate public families")
h.eq(public_families, state.families, "browser uses canonical sorted families")
for family, members in pairs(state.themes_by_family) do
	h.eq(vim.fn.sort(vim.deepcopy(members)), members, family .. " themes are sorted")
	h.falsy(vim.tbl_contains(members, "custom"), family .. " excludes custom")
end
h.eq("gruber", state.families[state.selected_family_index], "active family selection")
h.eq(
	"gruber-dark",
	state.themes_by_family.gruber[state.selected_theme_index],
	"active theme stored"
)
h.eq("gruber-dark", state.last_previewed_theme, "active theme is initial preview state")
h.eq(1, configured_calls, "opening built-in does not switch")

local selector_lines = vim.api.nvim_buf_get_lines(state.list_buffer, 0, -1, false)
h.eq("  1 Families    2 Themes  ", selector_lines[1], "tab line")
local family_rows = vim.list_slice(selector_lines, 2)
h.eq(public_families, family_rows, "family selector rows")
h.eq(
	state.selected_family_index + 1,
	vim.api.nvim_win_get_cursor(state.list_window)[1],
	"family cursor"
)
h.eq(" Neotheme · Families ", title(state.list_window), "family selector title")
h.eq(" Preview · gruber-dark ", title(state.preview_window), "initial preview title")

local marks = tab_marks(state)
h.eq(2, #marks, "tab highlight count")
h.eq(2, marks[1][3], "families tab column")
h.eq("NeothemeBrowserTabActive", marks[1][4].hl_group, "families active tab")
h.eq("NeothemeBrowserTabInactive", marks[2][4].hl_group, "themes inactive tab")

local list_config = vim.api.nvim_win_get_config(state.list_window)
local preview_config = vim.api.nvim_win_get_config(state.preview_window)
local backdrop_config = vim.api.nvim_win_get_config(state.backdrop_window)
h.eq("editor", list_config.relative, "selector is editor float")
h.eq("editor", preview_config.relative, "preview is editor float")
h.eq("editor", backdrop_config.relative, "backdrop is editor float")
h.eq(true, list_config.focusable, "selector is focusable")
h.eq(false, preview_config.focusable, "preview is non-focusable")
h.eq(false, backdrop_config.focusable, "backdrop is non-focusable")
h.truthy(backdrop_config.zindex < list_config.zindex, "backdrop zindex")
h.eq(list_config.zindex, preview_config.zindex, "surface zindex")
h.eq("╭", list_config.border[1], "selector rounded border")
h.eq("╭", preview_config.border[1], "preview rounded border")
h.eq("center", list_config.title_pos, "selector centered title")
h.eq("center", preview_config.title_pos, "preview centered title")
h.eq("NeothemeBrowserTitle", list_config.title[1][2], "selector title highlight")
h.eq("NeothemeBrowserTitle", preview_config.title[1][2], "preview title highlight")
h.eq(0, backdrop_config.row, "backdrop row")
h.eq(0, backdrop_config.col, "backdrop col")
h.eq(vim.o.columns, backdrop_config.width, "backdrop width")
h.eq(vim.o.lines - vim.o.cmdheight, backdrop_config.height, "backdrop height")
h.truthy(list_config.col + list_config.width + 2 <= preview_config.col, "actual float gap")
h.truthy(preview_config.col + preview_config.width + 2 <= vim.o.columns, "actual right bound")
h.truthy(
	preview_config.row + preview_config.height + 2 <= vim.o.lines - vim.o.cmdheight,
	"actual bottom bound"
)
h.eq(60, vim.wo[state.backdrop_window].winblend, "backdrop blend")
h.eq(0, vim.wo[state.list_window].winblend, "selector remains opaque")
h.eq(0, vim.wo[state.preview_window].winblend, "preview remains opaque")
h.truthy(
	vim.wo[state.backdrop_window].winhighlight:find("NeothemeBrowserBackdrop", 1, true),
	"backdrop highlight mapping"
)
h.truthy(
	vim.wo[state.list_window].winhighlight:find("NeothemeBrowserFloat", 1, true),
	"selector highlight mapping"
)
h.truthy(
	vim.wo[state.preview_window].winhighlight:find("NeothemeBrowserBorder", 1, true),
	"preview border mapping"
)
h.eq("Normal", highlight_link("NeothemeBrowserFloat"), "float highlight link")
h.eq("Normal", highlight_link("NeothemeBrowserBorder"), "border highlight link")
h.eq("Title", highlight_link("NeothemeBrowserTitle"), "title highlight link")
h.eq(0, vim.api.nvim_get_hl(0, { name = "NeothemeBrowserBackdrop" }).bg, "backdrop black")

for _, buffer in ipairs({ state.backdrop_buffer, state.list_buffer, state.preview_buffer }) do
	h.eq("nofile", vim.bo[buffer].buftype, "browser scratch buftype")
	h.eq("wipe", vim.bo[buffer].bufhidden, "browser scratch lifecycle")
	h.eq(false, vim.bo[buffer].swapfile, "browser scratch swapfile")
end
h.eq("lua", vim.bo[state.preview_buffer].filetype, "preview filetype")
h.eq("lua", vim.bo[state.preview_buffer].syntax, "preview syntax")
h.eq("yes", vim.wo[state.preview_window].signcolumn, "preview diagnostic sign column")

local fixture = table.concat(vim.api.nvim_buf_get_lines(state.preview_buffer, 0, -1, false), "\n")
for _, pattern in ipairs({
	"%-%- Neotheme preview",
	"local sample",
	'name = "neotheme"',
	"8, 16, 32",
	"local function describe%(theme, enabled%)",
	"if enabled and #theme.levels > 1 then",
	"string.format",
	"theme.name",
	"theme.levels%[2%]",
	"print%(describe%(sample, true%)%)",
}) do
	h.truthy(fixture:find(pattern), "preview fixture construct: " .. pattern)
end
local preview_diagnostics = vim.diagnostic.get(state.preview_buffer, {
	namespace = state.diagnostic_namespace,
})
h.eq(4, #preview_diagnostics, "preview diagnostic count")
local severities = {}
for _, diagnostic in ipairs(preview_diagnostics) do
	severities[diagnostic.severity] = true
end
h.eq({
	[vim.diagnostic.severity.ERROR] = true,
	[vim.diagnostic.severity.WARN] = true,
	[vim.diagnostic.severity.INFO] = true,
	[vim.diagnostic.severity.HINT] = true,
}, severities, "preview diagnostic severities")
h.truthy(#browser_autocmds() >= 6, "browser lifecycle autocmds")

local defensive = browser._state()
defensive.families[1] = "injected"
defensive.themes_by_family.gruber[1] = "injected"
h.eq("arcfield", browser._state().families[1], "browser family state is defensive")
h.eq("gruber-dark", browser._state().themes_by_family.gruber[1], "browser theme state is defensive")

vim.api.nvim_set_current_win(origin_window)
local duplicate_snapshot_count = 0
engine._snapshot_state = function()
	duplicate_snapshot_count = duplicate_snapshot_count + 1
	return original_snapshot()
end
browser.open()
engine._snapshot_state = original_snapshot
h.eq(state.list_window, vim.api.nvim_get_current_win(), "duplicate focuses selector")
h.eq(state.list_window, browser._state().list_window, "duplicate keeps selector")
h.eq(state.preview_window, browser._state().preview_window, "duplicate keeps preview")
h.eq(state.backdrop_window, browser._state().backdrop_window, "duplicate keeps backdrop")
h.eq(0, duplicate_snapshot_count, "duplicate does not take another snapshot")
h.eq(1, configured_calls, "duplicate does not preview")

press("<CR>")
local active_family_themes = assert(browser._state())
h.eq("themes", active_family_themes.mode, "enter drills into active family")
h.eq(1, configured_calls, "drilling active family does not switch")
h.eq(
	"gruber-dark",
	entries(active_family_themes)[active_family_themes.selected_theme_index],
	"active theme selected on drill"
)
local theme_lines = vim.api.nvim_buf_get_lines(active_family_themes.list_buffer, 0, -1, false)
h.eq(
	active_family_themes.themes_by_family.gruber,
	vim.list_slice(theme_lines, 2),
	"family theme rows"
)
h.eq(" Neotheme · gruber ", title(active_family_themes.list_window), "theme selector title")
marks = tab_marks(active_family_themes)
h.eq("NeothemeBrowserTabInactive", marks[1][4].hl_group, "families inactive tab")
h.eq("NeothemeBrowserTabActive", marks[2][4].hl_group, "themes active tab")

press("<BS>")
h.eq("families", browser._state().mode, "backspace returns to families")
local before_family_move = engine.current()
move_to("typeset")
h.eq(1, configured_calls, "family movement does not invoke configurator")
h.eq(before_family_move, engine.current(), "family movement does not preview")
h.eq(
	"typeset",
	browser._state().families[browser._state().selected_family_index],
	"family movement selection"
)

press("<CR>")
local typeset_state = assert(browser._state())
h.eq("themes", typeset_state.mode, "enter drills into different family")
h.eq("typeset-ink", typeset_state.last_previewed_theme, "different family previews first theme")
h.eq(2, configured_calls, "different family preview callback")
h.eq("typeset-ink", engine.current().active_theme, "different family preview active theme")
h.eq("dark", engine.current().background, "different family preview background")

press("<S-Tab>")
h.eq("families", browser._state().mode, "shift-tab switches to families")
press("<Tab>")
h.eq("themes", browser._state().mode, "tab switches to themes")
h.eq(2, configured_calls, "tab re-enters active family without preview")
press("h")
h.eq("families", browser._state().mode, "h switches to families")
press("l")
h.eq("themes", browser._state().mode, "l switches to themes")
press("1")
h.eq("families", browser._state().mode, "1 switches to families")
press("2")
h.eq("themes", browser._state().mode, "2 switches to themes")
h.eq(2, configured_calls, "mode controls do not duplicate preview")

move_to("typeset-paper")
local selected_state = assert(browser._state())
h.eq(3, configured_calls, "theme movement previews once")
h.eq("typeset-paper", selected_state.last_previewed_theme, "theme movement preview state")
h.eq("typeset-paper", engine.current().active_theme, "theme movement active theme")
h.eq("light", engine.current().background, "theme movement background")
h.eq(true, engine.current().session_override, "theme movement override")
h.falsy(h.highlight("NeothemeKeyword").bold, "preview retains configured typography")
h.falsy(h.highlight("NeothemeString").italic, "preview retains configured italics")
h.eq(
	h.color(engine.palette().ui.search),
	h.highlight("TelescopeMatching").fg,
	"preview integration"
)
h.eq({}, h.highlight("CmpItemAbbrMatch"), "preview disabled integration")
h.eq(" Preview · typeset-paper ", title(selected_state.preview_window), "preview title updates")
h.truthy(
	table
		.concat(vim.api.nvim_buf_get_lines(selected_state.preview_buffer, 0, -1, false), "\n")
		:find("family: typeset", 1, true),
	"preview family metadata updates"
)
move_to("typeset-paper")
h.eq(3, configured_calls, "same theme row does not re-preview")
h.truthy(#browser_autocmds() >= 6, "browser autocmds survive previews")
h.eq("Normal", highlight_link("NeothemeBrowserFloat"), "preview refreshes float highlight")
h.eq("Normal", highlight_link("NeothemeBrowserBorder"), "preview refreshes border highlight")
h.eq("Title", highlight_link("NeothemeBrowserTitle"), "preview refreshes title highlight")

for _, name in ipairs({
	"NeothemeBrowserFloat",
	"NeothemeBrowserBorder",
	"NeothemeBrowserTitle",
	"NeothemeBrowserTabActive",
	"NeothemeBrowserTabInactive",
	"NeothemeBrowserBackdrop",
}) do
	vim.api.nvim_set_hl(0, name, {})
end
vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false })
h.eq("Normal", highlight_link("NeothemeBrowserFloat"), "ColorScheme float refresh")
h.eq("Normal", highlight_link("NeothemeBrowserBorder"), "ColorScheme border refresh")
h.eq("Title", highlight_link("NeothemeBrowserTitle"), "ColorScheme title refresh")
h.eq(
	0,
	vim.api.nvim_get_hl(0, { name = "NeothemeBrowserBackdrop" }).bg,
	"ColorScheme backdrop refresh"
)

local cancel_restore_count = with_restore_counter(function()
	press_and_close("<Esc>")
end)
h.eq(1, cancel_restore_count, "escape restores exactly once")
h.eq(entry_state, runtime_state(), "escape restores exact entry state")
h.eq(3, configured_calls, "escape restore does not rerun configurator")
assert_clean(state, entry_resources, "escape cancellation")

local backdrop_entry = runtime_state()
local backdrop_resources = resources()
browser.open()
local backdrop_state = assert(browser._state())
vim.api.nvim_win_close(backdrop_state.backdrop_window, true)
h.truthy(browser._state() ~= nil, "closing backdrop does not cancel")
h.eq(backdrop_entry, runtime_state(), "closing backdrop does not change theme state")
h.truthy(vim.api.nvim_win_is_valid(backdrop_state.list_window), "selector survives backdrop close")
h.truthy(
	vim.api.nvim_win_is_valid(backdrop_state.preview_window),
	"preview survives backdrop close"
)
press_and_close("<Esc>")
assert_clean(backdrop_state, backdrop_resources, "backdrop close then cancellation")

local acceptance_config = config.get()
local accept_resources = resources()
browser.open()
local accept_state = assert(browser._state())
move_to("typeset")
press("<CR>")
h.eq("typeset-ink", engine.current().active_theme, "family drill preview before accept")
move_to("typeset-paper")
press_and_close("<CR>")
h.eq("typeset-paper", engine.current().active_theme, "accept keeps selected theme")
h.eq(true, engine.current().session_override, "accept keeps session override")
h.eq(acceptance_config, config.get(), "accept does not persist configuration")
assert_clean(accept_state, accept_resources, "acceptance")

local accepted_snapshot = engine._snapshot_state()
local accept_without_move_calls = configured_calls
local accept_without_move_resources = resources()
browser.open()
local accept_without_move_state = assert(browser._state())
h.eq(
	"typeset",
	accept_without_move_state.families[accept_without_move_state.selected_family_index],
	"accepted family initial selection"
)
press("<CR>")
h.eq("themes", browser._state().mode, "accept drill active family")
h.eq(accept_without_move_calls, configured_calls, "active family drill does not switch")
press_and_close("<CR>")
h.eq(accept_without_move_calls, configured_calls, "accept without theme movement does not switch")
h.eq(accepted_snapshot, engine._snapshot_state(), "accept without movement preserves state")
assert_clean(accept_without_move_state, accept_without_move_resources, "accept without move")

engine.reset()
local function alternate_close(label, close_resource)
	local expected_state = runtime_state()
	local expected_resources = resources()
	browser.open()
	local close_state = assert(browser._state())
	move_to("arcfield")
	press("<CR>")
	local restore_count = with_restore_counter(function()
		close_resource(close_state)
	end)
	h.eq(1, restore_count, label .. " restores exactly once")
	h.eq(expected_state, runtime_state(), label .. " exact state")
	assert_clean(close_state, expected_resources, label)
end

alternate_close("selector WinClosed", function(close_state)
	vim.api.nvim_win_close(close_state.list_window, true)
end)
alternate_close("preview WinClosed", function(close_state)
	vim.api.nvim_win_close(close_state.preview_window, true)
end)
alternate_close("selector BufWipeout", function(close_state)
	vim.api.nvim_buf_delete(close_state.list_buffer, { force = true })
end)

local normal_origin = vim.api.nvim_get_current_win()
vim.cmd.vsplit()
local disposable_origin = vim.api.nvim_get_current_win()
browser.open()
local deleted_origin_state = assert(browser._state())
h.eq(disposable_origin, deleted_origin_state.origin_window, "deletable origin captured")
vim.api.nvim_win_close(disposable_origin, true)
press_and_close("<Esc>")
h.falsy(vim.api.nvim_win_is_valid(disposable_origin), "origin remains deleted")
h.truthy(vim.api.nvim_win_is_valid(vim.api.nvim_get_current_win()), "focus remains valid")
vim.api.nvim_set_current_win(normal_origin)

local custom_calls = 0
engine.setup({
	theme = "custom",
	configure_palette = function(palette)
		custom_calls = custom_calls + 1
		fill_custom(palette)
	end,
})
engine.load()
h.eq(1, custom_calls, "custom browser fixture load reuses palette")
local custom_entry = runtime_state()
local custom_resources = resources()
browser.open()
local custom_state = assert(browser._state())
h.eq("families", custom_state.mode, "custom fallback remains family-first")
h.eq(
	"arcfield",
	custom_state.families[custom_state.selected_family_index],
	"custom fallback family"
)
h.eq("arcfield-graphite", custom_state.last_previewed_theme, "custom fallback theme")
h.eq("arcfield-graphite", engine.current().active_theme, "custom fallback active theme")
h.eq("custom", engine.current().configured_theme, "custom fallback configured theme")
h.eq(true, engine.current().session_override, "custom fallback override")
h.eq(2, custom_calls, "custom fallback callback once")
press("<CR>")
h.eq("themes", browser._state().mode, "custom fallback drills into themes")
h.eq(
	"arcfield-graphite",
	entries(browser._state())[browser._state().selected_theme_index],
	"custom fallback selected row"
)
h.eq(2, custom_calls, "custom fallback drill does not preview twice")
local custom_restore_count = with_restore_counter(function()
	press_and_close("<Esc>")
end)
h.eq(1, custom_restore_count, "custom cancellation restores exactly once")
h.eq(custom_entry, runtime_state(), "custom cancellation restores exact snapshot")
h.eq(2, custom_calls, "custom restoration does not rerun callback")
assert_clean(custom_state, custom_resources, "custom cancellation")

local custom_accept_config = config.get()
local custom_accept_resources = resources()
browser.open()
local custom_accept_state = assert(browser._state())
h.eq(3, custom_calls, "custom acceptance fallback callback")
press("<CR>")
press_and_close("<CR>")
h.eq("arcfield-graphite", engine.current().active_theme, "custom acceptance keeps fallback")
h.eq("custom", engine.current().configured_theme, "custom acceptance keeps configuration")
h.eq(true, engine.current().session_override, "custom acceptance keeps override")
h.eq(custom_accept_config, config.get(), "custom acceptance is non-persistent")
assert_clean(custom_accept_state, custom_accept_resources, "custom acceptance")
engine.reset()

engine.switch("gruber-dark")
local mismatch_calls = 0
engine.setup({
	theme = "typeset-paper",
	configure_palette = function(palette)
		mismatch_calls = mismatch_calls + 1
		palette.ui.accent = palette.diagnostic.information
	end,
	integrations = { gitsigns = true },
})
h.eq("gruber-dark", engine.current().active_theme, "setup leaves old browser entry applied")
h.eq(false, engine._snapshot_state().baseline_applied, "setup mismatch marker")
local mismatch_entry = runtime_state()
local mismatch_resources = resources()
browser.open()
local mismatch_state = assert(browser._state())
move_to("arcfield")
press("<CR>")
local mismatch_restore_count = with_restore_counter(function()
	press_and_close("<Esc>")
end)
h.eq(1, mismatch_restore_count, "setup mismatch restores once")
h.eq(mismatch_entry, runtime_state(), "setup mismatch restores exact snapshot")
h.eq(2, mismatch_calls, "setup mismatch restore does not rerun callback")
assert_clean(mismatch_state, mismatch_resources, "setup mismatch cancellation")

engine.reset()
engine.switch("gruber-light")
local override_entry = runtime_state()
local override_resources = resources()
browser.open()
local override_state = assert(browser._state())
move_to("typeset")
press("<CR>")
local override_restore_count = with_restore_counter(function()
	press_and_close("<Esc>")
end)
h.eq(1, override_restore_count, "override cancellation restores once")
h.eq(override_entry, runtime_state(), "override cancellation restores exact snapshot")
assert_clean(override_state, override_resources, "override cancellation")

engine.reset()
local creation_entry = runtime_state()
local creation_resources = resources()
local original_open_win = vim.api.nvim_open_win
for _, failure_at in ipairs({ 1, 2, 3 }) do
	local open_calls = 0
	vim.api.nvim_open_win = function(...)
		open_calls = open_calls + 1
		if open_calls == failure_at then
			error("intentional window creation failure " .. failure_at)
		end
		return original_open_win(...)
	end
	local creation_restore_count, creation_result = with_restore_counter(function()
		return { pcall(browser.open) }
	end)
	vim.api.nvim_open_win = original_open_win
	local creation_ok, creation_error = unpack(creation_result)
	h.falsy(creation_ok, "window creation failure must fail: " .. failure_at)
	h.truthy(
		tostring(creation_error):find("intentional window creation failure " .. failure_at, 1, true),
		"window creation error: " .. failure_at
	)
	h.eq(0, creation_restore_count, "pre-preview creation does not restore: " .. failure_at)
	h.eq(creation_entry, runtime_state(), "window creation preserves state: " .. failure_at)
	h.eq(nil, browser._state(), "window creation clears active state: " .. failure_at)
	h.eq(creation_resources, resources(), "window creation cleans resources: " .. failure_at)
	h.eq(0, #browser_autocmds(), "window creation cleans autocmds: " .. failure_at)
end

local initial_failure_calls = 0
local initial_failure_enabled = false
engine.setup({
	theme = "custom",
	configure_palette = function(palette)
		initial_failure_calls = initial_failure_calls + 1
		if initial_failure_enabled then
			error("intentional initial preview failure")
		end
		fill_custom(palette)
	end,
})
engine.load()
local initial_failure_entry = runtime_state()
local initial_failure_resources = resources()
initial_failure_enabled = true
local initial_restore_count, initial_result = with_restore_counter(function()
	return { pcall(browser.open) }
end)
h.eq(1, initial_restore_count, "initial preview failure restores exactly once")
h.eq(false, initial_result[1], "initial preview failure must fail")
h.truthy(
	tostring(initial_result[2]):find("intentional initial preview failure", 1, true),
	"initial preview failure error"
)
h.eq(initial_failure_entry, runtime_state(), "initial preview failure restores entry")
h.eq(initial_failure_resources, resources(), "initial preview failure cleans resources")
h.eq(nil, browser._state(), "initial preview failure clears active state")
h.eq(0, #browser_autocmds(), "initial preview failure cleans autocmds")
initial_failure_enabled = false

local preview_failure_calls = 0
local preview_failure_enabled = false
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		preview_failure_calls = preview_failure_calls + 1
		if preview_failure_enabled then
			error("intentional live preview failure")
		end
		palette.ui.search = palette.diagnostic.warning
	end,
	integrations = { telescope = true },
})
engine.reload()
h.eq(2, preview_failure_calls, "live failure fixture setup and reload")
local preview_failure_entry = runtime_state()
local preview_failure_resources = resources()
browser.open()
local preview_failure_state = assert(browser._state())
move_to("arcfield")
press("<CR>")
h.eq(3, preview_failure_calls, "successful family preview before failure")
preview_failure_enabled = true
local notifications = {}
local original_notify = vim.notify
vim.notify = function(message, level)
	table.insert(notifications, { message = message, level = level })
end
local live_restore_count = with_restore_counter(function()
	move_to("arcfield-porcelain")
end)
vim.notify = original_notify
h.eq(1, live_restore_count, "live preview failure restores exactly once")
h.eq(4, preview_failure_calls, "failed preview invokes callback once")
h.eq(preview_failure_entry, runtime_state(), "live preview failure restores entry")
h.eq(1, #notifications, "live preview failure reports once")
h.truthy(
	notifications[1].message:find("intentional live preview failure", 1, true),
	"live preview failure notification"
)
assert_clean(preview_failure_state, preview_failure_resources, "live preview failure")
preview_failure_enabled = false

local command_resources = resources()
local command_output = vim.api.nvim_exec2("Neotheme", { output = true }).output
h.eq("", command_output, "successful browser command is silent")
local command_state = assert(browser._state())
local duplicate_output = vim.api.nvim_exec2("Neotheme", { output = true }).output
h.eq("", duplicate_output, "duplicate browser command is silent")
h.eq(command_state.list_window, browser._state().list_window, "duplicate command keeps instance")
press_and_close("<Esc>")
assert_clean(command_state, command_resources, "browser command cancellation")
