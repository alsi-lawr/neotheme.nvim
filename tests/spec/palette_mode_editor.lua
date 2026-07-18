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

local function replace_field(surface, field, value)
	local row = assert(surface.field_lines[field])
	local line = lines(surface.editor_buffer)[row + 1]
	local replacement = assert(line:match("^(.-=%s*)")) .. value
	vim.api.nvim_buf_set_lines(surface.editor_buffer, row, row + 1, false, { replacement })
	vim.api.nvim_exec_autocmds("TextChanged", {
		buffer = surface.editor_buffer,
		modeline = false,
	})
	return row
end

local function replace_background(surface, value)
	local row = assert(surface.metadata_line)
	local line = lines(surface.editor_buffer)[row + 1]
	local replacement = assert(line:match("^(.-=%s*)")) .. value
	vim.api.nvim_buf_set_lines(surface.editor_buffer, row, row + 1, false, { replacement })
	vim.api.nvim_exec_autocmds("TextChanged", {
		buffer = surface.editor_buffer,
		modeline = false,
	})
end

local function create_from_add(mode, name)
	local original_select = vim.ui.select
	local original_input = vim.ui.input
	local sequence = {}
	vim.ui.select = function(items, options, callback)
		table.insert(sequence, "select")
		h.eq({ "Simplified palette", "Full palette" }, items, "Themes a exposes both modes")
		h.eq("New Neotheme palette mode: ", options.prompt, "mode select prompt is explicit")
		callback(mode)
	end
	vim.ui.input = function(options, callback)
		table.insert(sequence, "input")
		h.eq("New Neotheme theme: ", options.prompt, "mode select chains to name input")
		callback(name)
	end
	local ok, create_error = pcall(function()
		press("a")
	end)
	vim.ui.select = original_select
	vim.ui.input = original_input
	if not ok then
		error(create_error)
	end
	h.eq({ "select", "input" }, sequence, "mode selection precedes name input")
end

local function answer(value, action)
	local original = vim.ui.input
	vim.ui.input = function(_, callback)
		callback(value)
	end
	local ok, action_error = pcall(action)
	vim.ui.input = original
	if not ok then
		error(action_error)
	end
end

local function wait_closed(surface)
	vim.wait(1000, function()
		return editor._state() == nil
			and not vim.api.nvim_buf_is_valid(surface.navigator_buffer)
			and not vim.api.nvim_buf_is_valid(surface.navigator_frame_buffer)
			and not vim.api.nvim_buf_is_valid(surface.editor_buffer)
			and not vim.api.nvim_buf_is_valid(surface.editor_frame_buffer)
			and not vim.api.nvim_buf_is_valid(surface.preview_buffer)
	end)
end

for _, family in ipairs({ "modes", "target" }) do
	themes.create_family(family)
end
themes.clone("typeset-paper", "modes", "selected-full")
themes.clone("gruber-dark", "target", "selected-dark")
require("neotheme.commands").register()

vim.cmd("NeothemePalette")
local surface = assert(editor._state())
move_navigator(surface, "modes")
press("2")
move_navigator(assert(editor._state()), "user selected-full")
local selected_palette = themes.get("selected-full")
local configured_palette = require("neotheme")._configured_snapshot().palette
vim.o.background = "dark"
create_from_add("Simplified palette", "editor-simple")
surface = assert(editor._state())
local simple_record = assert(state.load().themes["editor-simple"])
h.eq("simplified", surface.mode, "simplified add opens the simplified editor")
h.eq("simplified", simple_record.mode, "simplified add persists compact mode")
h.eq(
	require("neotheme.neutral_simplified_palette").get("dark"),
	simple_record.palette,
	"simplified dark add uses fixed compact neutral source"
)
h.falsy(
	vim.deep_equal(selected_palette, themes.get("editor-simple")),
	"simplified add ignores selection"
)
h.falsy(
	vim.deep_equal(configured_palette, themes.get("editor-simple")),
	"simplified add ignores configured palette"
)
h.truthy(
	vim.inspect(vim.api.nvim_win_get_config(surface.editor_frame_window).title)
		:find("Simplified %- Surface"),
	"simplified title exposes mode and category"
)
h.eq(10, #lines(surface.editor_buffer), "simplified Surface has metadata plus nine fields")
local simple_tabs = table.concat(vim.list_slice(lines(surface.editor_frame_buffer), 1, 2), " ")
for _, tab in ipairs({ "1 Surface", "2 Text", "3 Syntax", "4 Signals" }) do
	h.truthy(simple_tabs:find(tab, 1, true), "simplified tabs include " .. tab)
end

vim.o.columns = 80
vim.o.lines = 24
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
surface = assert(editor._state())
local simple_view = vim.api.nvim_win_call(surface.editor_window, function()
	return { first = vim.fn.line("w0"), last = vim.fn.line("w$") }
end)
h.eq(1, simple_view.first, "80x24 simplified viewport shows background")
h.eq(#lines(surface.editor_buffer), simple_view.last, "80x24 simplified viewport shows all fields")
h.eq(
	"C-h nav | C commit | q close",
	lines(surface.editor_frame_buffer)[surface.layout.editor.height],
	"80x24 simplified viewport shows fixed help"
)
vim.o.columns = 140
vim.o.lines = 40
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })

surface = assert(editor._state())
replace_background(surface, "light")
surface = assert(editor._state())
h.eq("light", surface.record.background, "simplified background edit updates source metadata")
h.eq("light", surface.preview_background, "simplified background edit updates preview semantics")

press("4")
surface = assert(editor._state())
h.eq("signals", surface.category, "simplified numeric 4 selects Signals")
h.eq(3, #lines(surface.editor_buffer), "Signals has metadata plus two fields")
press("5")
h.eq("signals", editor._state().category, "simplified numeric 5 is unavailable")
press("]")
h.eq("surface", editor._state().category, "simplified ] wraps four categories")
press("[")
surface = assert(editor._state())
h.eq("signals", surface.category, "simplified [ wraps four categories")
local valid_preview = vim.api.nvim_get_hl(surface.preview_namespace, { name = "NeothemeError" })
local invalid_row = replace_field(surface, "diagnostic_error", "#123")
surface = assert(editor._state())
local diagnostics = vim.diagnostic.get(surface.editor_buffer, {
	namespace = surface.diagnostic_namespace,
})
h.eq(invalid_row, diagnostics[1].lnum, "simplified invalid token is field-local")
h.truthy(
	diagnostics[1].message:find("palette.diagnostic_error must be a #RRGGBB color", 1, true),
	"simplified diagnostic identifies flat source field"
)
h.eq(
	valid_preview,
	vim.api.nvim_get_hl(surface.preview_namespace, { name = "NeothemeError" }),
	"simplified invalid edit retains preview"
)
press("1")
h.eq("signals", editor._state().category, "invalid simplified edit blocks category movement")
h.falsy(pcall(vim.cmd, "write"), "invalid simplified edit blocks :write")

replace_field(surface, "diagnostic_error", "#cc3344")
surface = assert(editor._state())
h.eq(
	0xcc3344,
	vim.api.nvim_get_hl(surface.preview_namespace, { name = "NeothemeError" }).fg,
	"valid simplified edit updates expanded preview"
)
answer("Y", function()
	press("C")
end)
local committed = assert(state.load().themes["editor-simple"])
h.eq(2, committed.version, "C commits simplified record as v2")
h.eq("simplified", committed.mode, "C retains simplified source mode")
h.eq("light", committed.background, "C persists simplified background metadata")
h.eq("#cc3344", committed.palette.diagnostic_error, "C persists compact field")
h.eq("#cc3344", themes.get("editor-simple").diagnostic.error, "registry expands compact edit")
surface = assert(editor._state())
replace_field(surface, "version_control_conflict", "#aa4455")
vim.cmd("write")
h.eq(
	"#aa4455",
	state.load().themes["editor-simple"].palette.version_control_conflict,
	":write persists simplified source"
)
press("q")
wait_closed(surface)
