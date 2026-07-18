local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local editor = require("neotheme.palette_editor")
local palette = require("neotheme.palette")
local state = require("neotheme.state")
local themes = require("neotheme.themes")

vim.o.columns = 140
vim.o.lines = 40

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

themes.create_family("full-mode")
themes.clone("gruber-dark", "full-mode", "selected-dark")
require("neotheme.commands").register()
vim.cmd("NeothemePalette")
local surface = assert(editor._state())
move_navigator(surface, "full-mode")
press("2")
move_navigator(assert(editor._state()), "user selected-dark")
local selected = themes.get("selected-dark")
local configured = require("neotheme")._configured_snapshot().palette
local original_select = vim.ui.select
local original_input = vim.ui.input
vim.ui.select = function(items, options, callback)
	h.eq({ "Simplified palette", "Full palette" }, items, "full add starts with mode select")
	h.eq("New Neotheme palette mode: ", options.prompt, "full add mode prompt is explicit")
	callback("Full palette")
end
vim.ui.input = function(options, callback)
	h.eq("New Neotheme theme: ", options.prompt, "full add asks for a name second")
	callback("editor-full")
end
vim.o.background = "light"
press("a")
vim.ui.select = original_select
vim.ui.input = original_input

surface = assert(editor._state())
local record = assert(state.load().themes["editor-full"])
h.eq("full", surface.mode, "full add opens full editor")
h.eq(2, record.version, "full add writes v2")
h.eq("full", record.mode, "full add persists expanded source mode")
h.eq(
	require("neotheme.neutral_palette").get("light"),
	record.palette,
	"full light add uses fixed expanded neutral source"
)
h.falsy(vim.deep_equal(selected, record.palette), "full add ignores selected palette")
h.falsy(vim.deep_equal(configured, record.palette), "full add ignores configured palette")
h.truthy(
	vim.inspect(vim.api.nvim_win_get_config(surface.editor_frame_window).title)
		:find("Full %- Surface"),
	"full title exposes mode and category"
)
local tabs = table.concat(vim.list_slice(lines(surface.editor_frame_buffer), 1, 3), " ")
for _, tab in ipairs({
	"1 Surface",
	"2 Text",
	"3 Syntax",
	"4 Diagnostic",
	"5 Markup",
	"6 Version control",
	"7 UI",
}) do
	h.truthy(tabs:find(tab, 1, true), "full tabs include " .. tab)
end
press("5")
surface = assert(editor._state())
h.eq("markup", surface.category, "full numeric 5 selects Markup")
h.eq(15, #lines(surface.editor_buffer), "full Markup has metadata plus fourteen fields")
h.eq(59, #palette.paths(), "full editor retains the 59-role contract")

vim.o.columns = 80
vim.o.lines = 24
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
surface = assert(editor._state())
local view = vim.api.nvim_win_call(surface.editor_window, function()
	return { first = vim.fn.line("w0"), last = vim.fn.line("w$") }
end)
h.eq(1, view.first, "80x24 full viewport shows background")
h.eq(#lines(surface.editor_buffer), view.last, "80x24 full viewport shows worst category")
h.eq(
	"C-h nav | C commit | q close",
	lines(surface.editor_frame_buffer)[surface.layout.editor.height],
	"80x24 full viewport shows fixed help"
)
vim.o.columns = 140
vim.o.lines = 40
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
press("q")
h.eq(nil, editor._state(), "full editor q closes clean workspace state")
vim.wait(1000, function()
	return not vim.api.nvim_buf_is_valid(surface.editor_buffer)
end)
h.falsy(vim.api.nvim_buf_is_valid(surface.editor_buffer), "full editor cleanup deletes role buffer")
