local M = {}
local augroup_name = "NeothemeBrowser"
local diagnostic_namespace = nil
local tab_namespace = nil
local active = nil

local browser_winhighlight = table.concat({
	"Normal:NeothemeBrowserFloat",
	"NormalFloat:NeothemeBrowserFloat",
	"FloatBorder:NeothemeBrowserBorder",
	"FloatTitle:NeothemeBrowserTitle",
	"EndOfBuffer:NeothemeBrowserFloat",
}, ",")
local backdrop_winhighlight = table.concat({
	"Normal:NeothemeBrowserBackdrop",
	"NormalFloat:NeothemeBrowserBackdrop",
	"EndOfBuffer:NeothemeBrowserBackdrop",
}, ",")

local preview_lines = {
	"-- Neotheme preview · family: %s",
	"local sample = {",
	'  name = "neotheme",',
	"  levels = { 8, 16, 32 },",
	"}",
	"local function describe(theme, enabled)",
	"  if enabled and #theme.levels > 1 then",
	'    return string.format("%s:%d", theme.name, theme.levels[2])',
	"  end",
	'  return "disabled"',
	"end",
	"print(describe(sample, true))",
}

local diagnostics = {
	{
		lnum = 2,
		col = 2,
		end_col = 6,
		severity = vim.diagnostic.severity.ERROR,
		message = "Error sample",
	},
	{
		lnum = 3,
		col = 13,
		end_col = 15,
		severity = vim.diagnostic.severity.WARN,
		message = "Warning sample",
	},
	{
		lnum = 8,
		col = 2,
		end_col = 5,
		severity = vim.diagnostic.severity.INFO,
		message = "Information sample",
	},
	{
		lnum = 9,
		col = 2,
		end_col = 8,
		severity = vim.diagnostic.severity.HINT,
		message = "Hint sample",
	},
}

local function copy(value)
	if type(value) ~= "table" then
		return value
	end

	local result = {}
	for key, item in pairs(value) do
		result[key] = copy(item)
	end
	return result
end

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function apply_highlights()
	vim.api.nvim_set_hl(0, "NeothemeBrowserFloat", { link = "Normal" })
	vim.api.nvim_set_hl(0, "NeothemeBrowserBorder", { link = "Normal" })
	vim.api.nvim_set_hl(0, "NeothemeBrowserTitle", { link = "Title" })
	vim.api.nvim_set_hl(0, "NeothemeBrowserTabActive", { link = "Title" })
	vim.api.nvim_set_hl(0, "NeothemeBrowserTabInactive", { link = "Comment" })
	vim.api.nvim_set_hl(0, "NeothemeBrowserBackdrop", { bg = "#000000" })
end

---@param columns integer
---@param usable_rows integer
---@param longest_name integer
---@return table? layout
---@return string? error_message
function M._layout(columns, usable_rows, longest_name)
	if columns < 64 or usable_rows < 18 then
		return nil, "neotheme: the theme browser requires at least 64 columns and 18 usable rows"
	end

	local total_width = math.min(100, columns - 4)
	local list_width = clamp(longest_name + 2, 26, 32)
	local preview_width = total_width - list_width - 5
	if preview_width < 29 then
		return nil, "neotheme: the editor is too narrow for the theme browser"
	end

	local height = math.min(22, usable_rows - 6)
	local outer_height = height + 2
	local row = math.floor((usable_rows - outer_height) / 2)
	local col = math.floor((columns - total_width) / 2)
	local preview_col = col + list_width + 3

	return {
		outer = {
			row = row,
			col = col,
			width = total_width,
			height = outer_height,
		},
		backdrop = {
			row = 0,
			col = 0,
			width = columns,
			height = usable_rows,
		},
		list = {
			row = row,
			col = col,
			width = list_width,
			height = height,
		},
		preview = {
			row = row,
			col = preview_col,
			width = preview_width,
			height = height,
		},
	}
end

local function valid_window(window)
	return window ~= nil and vim.api.nvim_win_is_valid(window)
end

local function valid_buffer(buffer)
	return buffer ~= nil and vim.api.nvim_buf_is_valid(buffer)
end

local function set_window_title(window, text)
	local window_config = vim.api.nvim_win_get_config(window)
	window_config.title = { { text, "NeothemeBrowserTitle" } }
	window_config.title_pos = "center"
	vim.api.nvim_win_set_config(window, window_config)
end

local function selected_family(browser)
	return browser.families[browser.selected_family_index]
end

local function selected_theme(browser)
	local family = selected_family(browser)
	return browser.themes_by_family[family][browser.selected_theme_index]
end

local function selector_entries(browser)
	if browser.mode == "families" then
		return browser.families, browser.selected_family_index
	end
	return browser.themes_by_family[selected_family(browser)], browser.selected_theme_index
end

local function update_preview_metadata(browser, theme)
	local family = browser.theme_families[theme]
	set_window_title(browser.preview_window, " Preview · " .. theme .. " ")

	vim.api.nvim_set_option_value("modifiable", true, { buf = browser.preview_buffer })
	vim.api.nvim_buf_set_lines(
		browser.preview_buffer,
		0,
		1,
		false,
		{ string.format(preview_lines[1], family) }
	)
	vim.api.nvim_set_option_value("modifiable", false, { buf = browser.preview_buffer })
end

local function render_tabs(browser)
	local line = "  1 Families    2 Themes  "
	local families_start = assert(line:find("1 Families", 1, true)) - 1
	local themes_start = assert(line:find("2 Themes", 1, true)) - 1
	local active_group = "NeothemeBrowserTabActive"
	local inactive_group = "NeothemeBrowserTabInactive"

	vim.api.nvim_buf_clear_namespace(browser.list_buffer, tab_namespace, 0, 1)
	vim.api.nvim_buf_set_extmark(browser.list_buffer, tab_namespace, 0, families_start, {
		end_col = families_start + #"1 Families",
		hl_group = browser.mode == "families" and active_group or inactive_group,
	})
	vim.api.nvim_buf_set_extmark(browser.list_buffer, tab_namespace, 0, themes_start, {
		end_col = themes_start + #"2 Themes",
		hl_group = browser.mode == "themes" and active_group or inactive_group,
	})
end

local function render_selector(browser)
	local entries, index = selector_entries(browser)
	local lines = { "  1 Families    2 Themes  " }
	vim.list_extend(lines, entries)

	browser.rendering = true
	vim.api.nvim_set_option_value("modifiable", true, { buf = browser.list_buffer })
	vim.api.nvim_buf_set_lines(browser.list_buffer, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = browser.list_buffer })
	render_tabs(browser)
	vim.api.nvim_win_set_cursor(browser.list_window, { index + 1, 0 })
	browser.rendering = false

	if browser.mode == "families" then
		set_window_title(browser.list_window, " Neotheme · Families ")
	else
		set_window_title(browser.list_window, " Neotheme · " .. selected_family(browser) .. " ")
	end
end

local function restore_focus(browser)
	if valid_window(browser.origin_window) then
		pcall(vim.api.nvim_set_current_win, browser.origin_window)
	end
end

local function delete_augroup(browser)
	if browser.augroup ~= nil then
		pcall(vim.api.nvim_del_augroup_by_id, browser.augroup)
		browser.augroup = nil
	end
end

local function cleanup_resources(browser)
	delete_augroup(browser)

	if diagnostic_namespace ~= nil and valid_buffer(browser.preview_buffer) then
		pcall(vim.diagnostic.reset, diagnostic_namespace, browser.preview_buffer)
	end

	for _, field in ipairs({ "list_window", "preview_window", "backdrop_window" }) do
		local window = browser[field]
		if valid_window(window) then
			pcall(vim.api.nvim_win_close, window, true)
		end
	end

	for _, field in ipairs({ "list_buffer", "preview_buffer", "backdrop_buffer" }) do
		local buffer = browser[field]
		if valid_buffer(buffer) then
			pcall(vim.api.nvim_buf_delete, buffer, { force = true })
		end
	end

	if active == browser then
		active = nil
	end
	restore_focus(browser)
end

local function report_error(message)
	pcall(vim.notify, message, vim.log.levels.ERROR)
end

local function restore_entry(browser)
	if browser.restored then
		return true
	end

	browser.restored = true
	return pcall(require("neotheme")._restore_state, browser.entry_snapshot)
end

local function cancel(browser, message)
	if browser.closing then
		return
	end

	browser.closing = true
	local restored, restore_error = restore_entry(browser)
	cleanup_resources(browser)

	if message then
		report_error(message)
	end
	if not restored then
		report_error(
			"neotheme: failed to restore the browser entry state: " .. tostring(restore_error)
		)
	end
end

local function perform_preview(browser, theme)
	if browser.closing or browser.previewing or theme == browser.last_previewed_theme then
		return true
	end

	browser.previewing = true
	browser.preview_attempted = true
	local ok, preview_error = pcall(function()
		require("neotheme").switch(theme)
		browser.previewed = true
		browser.last_previewed_theme = theme
		apply_highlights()
		update_preview_metadata(browser, theme)
	end)
	browser.previewing = false

	return ok, preview_error
end

local function preview_or_cancel(browser, theme)
	local ok, preview_error = perform_preview(browser, theme)
	if not ok then
		cancel(browser, "neotheme: failed to preview theme: " .. tostring(preview_error))
	end
	return ok
end

local function theme_index(browser, family, theme)
	for index, name in ipairs(browser.themes_by_family[family]) do
		if name == theme then
			return index
		end
	end
	return nil
end

local function show_families(browser)
	if browser.closing or browser.mode == "families" then
		return
	end

	browser.mode = "families"
	render_selector(browser)
end

local function show_themes(browser)
	if browser.closing or browser.mode == "themes" then
		return true
	end

	local family = selected_family(browser)
	local current_index = theme_index(browser, family, browser.last_previewed_theme)
	local index = current_index or 1
	local theme = browser.themes_by_family[family][index]
	if not current_index and not preview_or_cancel(browser, theme) then
		return false
	end

	browser.selected_theme_index = index
	browser.mode = "themes"
	render_selector(browser)
	return true
end

local function toggle_mode(browser)
	if browser.mode == "families" then
		show_themes(browser)
	else
		show_families(browser)
	end
end

local function selector_index(browser)
	local entries, current_index = selector_entries(browser)
	if not valid_window(browser.list_window) then
		return current_index
	end

	local row = vim.api.nvim_win_get_cursor(browser.list_window)[1]
	return clamp(row - 1, 1, #entries)
end

local function handle_movement(browser)
	if browser.closing or browser.previewing or browser.rendering then
		return
	end

	local index = selector_index(browser)
	if vim.api.nvim_win_get_cursor(browser.list_window)[1] == 1 then
		render_selector(browser)
		return
	end

	if browser.mode == "families" then
		browser.selected_family_index = index
		local family = selected_family(browser)
		browser.selected_theme_index = theme_index(browser, family, browser.last_previewed_theme)
			or 1
		return
	end

	if index == browser.selected_theme_index then
		return
	end
	local theme = browser.themes_by_family[selected_family(browser)][index]
	if preview_or_cancel(browser, theme) then
		browser.selected_theme_index = index
	end
end

local function accept(browser)
	if browser.closing then
		return
	end
	if browser.mode == "families" then
		show_themes(browser)
		return
	end

	if not preview_or_cancel(browser, selected_theme(browser)) then
		return
	end

	browser.accepted = true
	browser.closing = true
	cleanup_resources(browser)
end

local function create_buffer(name, lines)
	local buffer = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buffer, string.format("neotheme://browser/%s/%d", name, buffer))
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buffer })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buffer })
	vim.api.nvim_set_option_value("swapfile", false, { buf = buffer })
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buffer })
	return buffer
end

local function configure_browser_window(window)
	vim.api.nvim_set_option_value("number", false, { win = window })
	vim.api.nvim_set_option_value("relativenumber", false, { win = window })
	vim.api.nvim_set_option_value("wrap", false, { win = window })
	vim.api.nvim_set_option_value("winblend", 0, { win = window })
	vim.api.nvim_set_option_value("winhighlight", browser_winhighlight, { win = window })
end

local function configure_list_window(browser)
	configure_browser_window(browser.list_window)
	vim.api.nvim_set_option_value("cursorline", true, { win = browser.list_window })
	vim.api.nvim_set_option_value("signcolumn", "no", { win = browser.list_window })

	local mapping_options = { buffer = browser.list_buffer, nowait = true, silent = true }
	vim.keymap.set("n", "<Esc>", function()
		cancel(browser)
	end, mapping_options)
	vim.keymap.set("n", "<CR>", function()
		accept(browser)
	end, mapping_options)
	vim.keymap.set("n", "<Tab>", function()
		toggle_mode(browser)
	end, mapping_options)
	vim.keymap.set("n", "<S-Tab>", function()
		toggle_mode(browser)
	end, mapping_options)
	vim.keymap.set("n", "h", function()
		show_families(browser)
	end, mapping_options)
	vim.keymap.set("n", "l", function()
		show_themes(browser)
	end, mapping_options)
	vim.keymap.set("n", "1", function()
		show_families(browser)
	end, mapping_options)
	vim.keymap.set("n", "2", function()
		show_themes(browser)
	end, mapping_options)
	vim.keymap.set("n", "<BS>", function()
		show_families(browser)
	end, mapping_options)
	vim.keymap.set("n", "<C-h>", function()
		show_families(browser)
	end, mapping_options)
end

local function configure_preview(browser)
	configure_browser_window(browser.preview_window)
	vim.api.nvim_set_option_value("filetype", "lua", { buf = browser.preview_buffer })
	vim.api.nvim_set_option_value("signcolumn", "yes", { win = browser.preview_window })

	if diagnostic_namespace == nil then
		diagnostic_namespace = vim.api.nvim_create_namespace("NeothemeBrowser")
	end
	vim.diagnostic.set(diagnostic_namespace, browser.preview_buffer, diagnostics, {
		severity_sort = true,
		signs = true,
		underline = true,
		virtual_text = { spacing = 1 },
	})
	pcall(vim.treesitter.start, browser.preview_buffer, "lua")
	vim.api.nvim_set_option_value("syntax", "lua", { buf = browser.preview_buffer })
	update_preview_metadata(browser, browser.initial_theme)
end

local function configure_backdrop(browser)
	vim.api.nvim_set_option_value("winblend", 60, { win = browser.backdrop_window })
	vim.api.nvim_set_option_value("winhighlight", backdrop_winhighlight, {
		win = browser.backdrop_window,
	})
end

local function create_lifecycle_autocmds(browser)
	browser.augroup = vim.api.nvim_create_augroup(augroup_name, { clear = true })

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = browser.augroup,
		callback = apply_highlights,
		desc = "Refresh Neotheme browser float highlights",
	})

	vim.api.nvim_create_autocmd("CursorMoved", {
		group = browser.augroup,
		buffer = browser.list_buffer,
		callback = function()
			if active == browser then
				handle_movement(browser)
			end
		end,
		desc = "Navigate the Neotheme browser selector",
	})

	for _, window in ipairs({ browser.list_window, browser.preview_window }) do
		vim.api.nvim_create_autocmd("WinClosed", {
			group = browser.augroup,
			pattern = tostring(window),
			callback = function()
				if active == browser and not browser.closing then
					cancel(browser)
				end
			end,
			desc = "Cancel Neotheme browser when a surface closes",
		})
	end

	for _, buffer in ipairs({ browser.list_buffer, browser.preview_buffer }) do
		vim.api.nvim_create_autocmd("BufWipeout", {
			group = browser.augroup,
			buffer = buffer,
			callback = function()
				if active == browser and not browser.closing then
					cancel(browser)
				end
			end,
			desc = "Cancel Neotheme browser when a surface buffer is wiped",
		})
	end
end

local function inventory()
	local engine = require("neotheme")
	local families = {}
	local themes_by_family = {}
	local theme_families = {}
	local longest_name = 0

	for _, family in ipairs(engine.families()) do
		local members = {}
		for _, theme in ipairs(engine.themes(family)) do
			if theme ~= "custom" then
				table.insert(members, theme)
			end
		end
		table.sort(members)
		if #members > 0 then
			table.insert(families, family)
			themes_by_family[family] = members
			longest_name = math.max(longest_name, vim.fn.strdisplaywidth(family))
			for _, theme in ipairs(members) do
				theme_families[theme] = family
				longest_name = math.max(longest_name, vim.fn.strdisplaywidth(theme))
			end
		end
	end
	table.sort(families)

	return families, themes_by_family, theme_families, longest_name
end

local function initial_selection(families, themes_by_family, theme_families, active_theme)
	local family = theme_families[active_theme] or families[1]
	local family_index = 1
	for index, name in ipairs(families) do
		if name == family then
			family_index = index
			break
		end
	end

	local theme_index = 1
	local listed = theme_families[active_theme] ~= nil
	if listed then
		for index, name in ipairs(themes_by_family[family]) do
			if name == active_theme then
				theme_index = index
				break
			end
		end
	end

	return family_index, theme_index, listed
end

local function create_browser(browser)
	apply_highlights()
	local family = selected_family(browser)
	local lines = copy(preview_lines)
	lines[1] = string.format(lines[1], family)

	browser.backdrop_buffer = create_buffer("backdrop", { "" })
	browser.list_buffer = create_buffer("selector", { "" })
	browser.preview_buffer = create_buffer("preview", lines)
	browser.backdrop_window = vim.api.nvim_open_win(browser.backdrop_buffer, false, {
		relative = "editor",
		row = browser.layout.backdrop.row,
		col = browser.layout.backdrop.col,
		width = browser.layout.backdrop.width,
		height = browser.layout.backdrop.height,
		style = "minimal",
		focusable = false,
		zindex = 40,
	})
	browser.list_window = vim.api.nvim_open_win(browser.list_buffer, true, {
		relative = "editor",
		row = browser.layout.list.row,
		col = browser.layout.list.col,
		width = browser.layout.list.width,
		height = browser.layout.list.height,
		style = "minimal",
		border = "rounded",
		title = { { " Neotheme · Families ", "NeothemeBrowserTitle" } },
		title_pos = "center",
		focusable = true,
		zindex = 50,
	})
	browser.preview_window = vim.api.nvim_open_win(browser.preview_buffer, false, {
		relative = "editor",
		row = browser.layout.preview.row,
		col = browser.layout.preview.col,
		width = browser.layout.preview.width,
		height = browser.layout.preview.height,
		style = "minimal",
		border = "rounded",
		title = { { " Preview · " .. browser.initial_theme .. " ", "NeothemeBrowserTitle" } },
		title_pos = "center",
		focusable = false,
		zindex = 50,
	})

	configure_backdrop(browser)
	configure_list_window(browser)
	configure_preview(browser)
	if tab_namespace == nil then
		tab_namespace = vim.api.nvim_create_namespace("NeothemeBrowserTabs")
	end
	render_selector(browser)
	create_lifecycle_autocmds(browser)
	active = browser

	if not browser.initial_theme_listed then
		local ok, preview_error = perform_preview(browser, browser.initial_theme)
		if not ok then
			error(preview_error)
		end
	end
end

function M.open()
	if active ~= nil then
		if valid_window(active.list_window) then
			vim.api.nvim_set_current_win(active.list_window)
			return
		end
		cancel(active)
	end

	local engine = require("neotheme")
	local current = engine.current()
	if not current.loaded or type(current.active_theme) ~= "string" then
		error("neotheme: the theme browser requires Neotheme to be loaded", 2)
	end

	local families, themes_by_family, theme_families, longest_name = inventory()
	if #families == 0 then
		error("neotheme: the theme browser has no built-in themes to display", 2)
	end

	local layout, layout_error =
		M._layout(vim.o.columns, vim.o.lines - vim.o.cmdheight, longest_name)
	if not layout then
		error(layout_error, 2)
	end

	local family_index, theme_index, listed =
		initial_selection(families, themes_by_family, theme_families, current.active_theme)
	local family = families[family_index]
	local initial_theme = listed and current.active_theme or themes_by_family[family][theme_index]
	local browser = {
		accepted = false,
		closing = false,
		mode = "families",
		previewed = false,
		previewing = false,
		rendering = false,
		restored = false,
		origin_window = vim.api.nvim_get_current_win(),
		entry_snapshot = engine._snapshot_state(),
		families = families,
		themes_by_family = themes_by_family,
		theme_families = theme_families,
		layout = layout,
		selected_family_index = family_index,
		selected_theme_index = theme_index,
		initial_theme = initial_theme,
		initial_theme_listed = listed,
		last_previewed_theme = listed and current.active_theme or nil,
	}

	local ok, creation_error = xpcall(function()
		create_browser(browser)
	end, debug.traceback)
	if not ok then
		browser.closing = true
		local restored, restore_error = true, nil
		if browser.preview_attempted then
			restored, restore_error = restore_entry(browser)
		end
		cleanup_resources(browser)
		local message = "neotheme: failed to open the theme browser: " .. tostring(creation_error)
		if not restored then
			message = message .. "; failed to restore entry state: " .. tostring(restore_error)
		end
		error(message, 2)
	end
end

---@return table?
function M._state()
	if active == nil then
		return nil
	end

	return copy({
		backdrop_window = active.backdrop_window,
		backdrop_buffer = active.backdrop_buffer,
		list_window = active.list_window,
		preview_window = active.preview_window,
		list_buffer = active.list_buffer,
		preview_buffer = active.preview_buffer,
		diagnostic_namespace = diagnostic_namespace,
		tab_namespace = tab_namespace,
		origin_window = active.origin_window,
		augroup = active.augroup,
		families = active.families,
		themes_by_family = active.themes_by_family,
		theme_families = active.theme_families,
		layout = active.layout,
		mode = active.mode,
		selected_family_index = active.selected_family_index,
		selected_theme_index = active.selected_theme_index,
		last_previewed_theme = active.last_previewed_theme,
	})
end

return M
