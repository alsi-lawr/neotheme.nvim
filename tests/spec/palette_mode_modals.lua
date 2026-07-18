local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local editor = require("neotheme.palette_editor")
local state = require("neotheme.state")
local themes = require("neotheme.themes")

vim.o.columns = 100
vim.o.lines = 30

local function lines(buffer)
	return vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
end

local function find_line(buffer, expected)
	for index, line in ipairs(lines(buffer)) do
		if line:find(expected, 1, true) then
			return index
		end
	end
	error("missing workspace text: " .. expected)
end

local function press(key)
	vim.api.nvim_feedkeys(vim.keycode(key), "x", false)
end

local function move_navigator(surface, expected)
	vim.api.nvim_set_current_win(surface.navigator_window)
	vim.api.nvim_win_set_cursor(
		surface.navigator_window,
		{ find_line(surface.navigator_buffer, expected), 0 }
	)
	vim.api.nvim_exec_autocmds("CursorMoved", {
		buffer = surface.navigator_buffer,
		modeline = false,
	})
end

local workspace_windows = {
	"navigator_frame_window",
	"navigator_window",
	"editor_frame_window",
	"editor_window",
	"preview_window",
}

local workspace_buffers = {
	"navigator_buffer",
	"navigator_frame_buffer",
	"editor_buffer",
	"editor_frame_buffer",
	"preview_buffer",
}

local function open_provider_modal(label)
	local surface = assert(editor._state())
	local return_window = vim.api.nvim_get_current_win()
	local buffer = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { label })
	local window = vim.api.nvim_open_win(buffer, true, {
		relative = "editor",
		row = 2,
		col = 20,
		width = 40,
		height = 3,
		style = "minimal",
		border = "rounded",
		focusable = true,
		zindex = 50,
	})
	local config = vim.api.nvim_win_get_config(window)
	h.eq(50, config.zindex, label .. " uses provider z-index 50")
	h.eq(true, config.focusable, label .. " is focusable")
	h.falsy(config.hide, label .. " is visible")
	h.eq(window, vim.api.nvim_get_current_win(), label .. " receives focus")
	for _, field in ipairs(workspace_windows) do
		h.truthy(
			vim.api.nvim_win_get_config(surface[field]).zindex < config.zindex,
			label .. " is above " .. field
		)
	end
	return { buffer = buffer, window = window, return_window = return_window }
end

local function close_provider_modal(modal)
	if vim.api.nvim_win_is_valid(modal.window) then
		vim.api.nvim_win_close(modal.window, true)
	end
	if vim.api.nvim_buf_is_valid(modal.buffer) then
		vim.api.nvim_buf_delete(modal.buffer, { force = true })
	end
	if vim.api.nvim_win_is_valid(modal.return_window) then
		vim.api.nvim_set_current_win(modal.return_window)
	end
end

local function close_workspace(surface, label)
	vim.api.nvim_set_current_win(surface.navigator_window)
	press("q")
	h.eq(nil, editor._state(), label .. " clears active state")
	vim.wait(1000, function()
		for _, field in ipairs(workspace_windows) do
			if vim.api.nvim_win_is_valid(surface[field]) then
				return false
			end
		end
		for _, field in ipairs(workspace_buffers) do
			if vim.api.nvim_buf_is_valid(surface[field]) then
				return false
			end
		end
		return true
	end)
	for _, field in ipairs(workspace_windows) do
		h.falsy(vim.api.nvim_win_is_valid(surface[field]), label .. " closes " .. field)
	end
end

themes.create_family("modal-mode")
require("neotheme.commands").register()

vim.cmd("NeothemePalette")
local surface = assert(editor._state())
move_navigator(surface, "modal-mode")
press("2")
surface = assert(editor._state())
local before = select(2, themes.inventory())["modal-mode"]
local original_select = vim.ui.select
local original_input = vim.ui.input
local input_called = false
vim.ui.select = function(_, _, callback)
	callback(nil)
end
vim.ui.input = function()
	input_called = true
end
press("a")
vim.ui.select = original_select
vim.ui.input = original_input
h.falsy(input_called, "select cancellation does not open name input")
h.eq(before, select(2, themes.inventory())["modal-mode"], "select cancellation is a no-op")

original_select = vim.ui.select
original_input = vim.ui.input
vim.ui.select = function(_, _, callback)
	callback("Simplified palette")
end
vim.ui.input = function(_, callback)
	callback(nil)
end
press("a")
vim.ui.select = original_select
vim.ui.input = original_input
h.eq(before, select(2, themes.inventory())["modal-mode"], "name cancellation is a no-op")

local sequence = {}
original_select = vim.ui.select
original_input = vim.ui.input
vim.ui.select = function(items, options, callback)
	table.insert(sequence, "select")
	h.eq({ "Simplified palette", "Full palette" }, items, "provider select exposes both modes")
	h.eq("New Neotheme palette mode: ", options.prompt, "provider select prompt is visible")
	local modal = open_provider_modal("mode select")
	close_provider_modal(modal)
	callback("Simplified palette")
end
vim.ui.input = function(options, callback)
	table.insert(sequence, "input")
	h.eq("New Neotheme theme: ", options.prompt, "provider input follows select")
	local modal = open_provider_modal("name input")
	close_provider_modal(modal)
	callback("modal-simple")
end
press("a")
vim.ui.select = original_select
vim.ui.input = original_input
h.eq({ "select", "input" }, sequence, "visible mode select chains to visible name input")
h.eq("simplified", state.load().themes["modal-simple"].mode, "provider chain persists mode")
surface = assert(editor._state())
close_workspace(surface, "provider chain workspace")

vim.cmd("NeothemePalette")
surface = assert(editor._state())
move_navigator(surface, "modal-mode")
press("2")
local stale_select_callback
local stale_select_modal
local stale_input_called = false
original_select = vim.ui.select
original_input = vim.ui.input
vim.ui.select = function(_, _, callback)
	stale_select_modal = open_provider_modal("stale mode select")
	stale_select_callback = callback
end
vim.ui.input = function()
	stale_input_called = true
end
press("a")
vim.ui.select = original_select
vim.ui.input = original_input
local stale_select_surface = assert(editor._state())
close_workspace(stale_select_surface, "stale select workspace")
h.truthy(vim.api.nvim_win_is_valid(stale_select_modal.window), "provider owns stale select cleanup")
close_provider_modal(stale_select_modal)
stale_select_callback("Full palette")
h.falsy(stale_input_called, "stale select callback cannot open name input")

vim.cmd("NeothemePalette")
surface = assert(editor._state())
move_navigator(surface, "modal-mode")
press("2")
local stale_name_callback
local stale_name_modal
original_select = vim.ui.select
original_input = vim.ui.input
vim.ui.select = function(_, _, callback)
	callback("Full palette")
end
vim.ui.input = function(_, callback)
	stale_name_modal = open_provider_modal("stale name input")
	stale_name_callback = callback
end
press("a")
vim.ui.select = original_select
vim.ui.input = original_input
local stale_name_surface = assert(editor._state())
close_workspace(stale_name_surface, "stale name workspace")
h.truthy(vim.api.nvim_win_is_valid(stale_name_modal.window), "provider owns stale input cleanup")
close_provider_modal(stale_name_modal)
stale_name_callback("stale-mode-theme")
h.falsy(themes.is_user("stale-mode-theme"), "stale name callback cannot persist")
