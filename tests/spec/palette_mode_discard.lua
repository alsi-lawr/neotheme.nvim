local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local editor = require("neotheme.palette_editor")
local state = require("neotheme.state")
local themes = require("neotheme.themes")

vim.o.columns = 100
vim.o.lines = 30

local function press(key)
	vim.api.nvim_feedkeys(vim.keycode(key), "x", false)
end

local function lines(buffer)
	return vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
end

local function file_bytes(path)
	return table.concat(vim.fn.readfile(path, "b"), "\n")
end

themes.create_family("discard")
themes.create_snapshot({
	background = "dark",
	mode = "simplified",
	palette = require("neotheme.neutral_simplified_palette").get("dark"),
}, "discard", "discard-simple")
local path = vim.fs.joinpath(state.root(), "palettes", "discard", "discard-simple.json")
local before = file_bytes(path)

editor.edit("discard-simple")
press("4")
local surface = assert(editor._state())
h.eq("simplified", surface.mode, "discard fixture uses simplified mode")
h.eq("signals", surface.category, "discard fixture exposes Signals")
local trailing_row = vim.api.nvim_buf_line_count(surface.editor_buffer)
vim.api.nvim_buf_set_lines(
	surface.editor_buffer,
	trailing_row,
	trailing_row,
	false,
	{ "derived_override = #123456" }
)
vim.api.nvim_exec_autocmds("TextChanged", {
	buffer = surface.editor_buffer,
	modeline = false,
})
surface = assert(editor._state())
local malformed = lines(surface.editor_buffer)
local diagnostics = vim.diagnostic.get(surface.editor_buffer, {
	namespace = surface.diagnostic_namespace,
})
h.eq(trailing_row, diagnostics[1].lnum, "simplified surplus row diagnostic is in place")
h.truthy(
	diagnostics[1].message:find("unknown field derived_override", 1, true),
	"simplified source rejects derived-role overrides"
)
h.truthy(surface.dirty, "simplified structural violation remains dirty")
press("1")
h.eq("signals", editor._state().category, "structural violation blocks category movement")
h.eq(malformed, lines(surface.editor_buffer), "blocked movement preserves malformed source")
h.falsy(pcall(vim.cmd, "write"), "structural violation blocks :write")
h.eq(before, file_bytes(path), "blocked simplified write preserves bytes")

local windows = {
	surface.navigator_window,
	surface.navigator_frame_window,
	surface.editor_window,
	surface.editor_frame_window,
	surface.preview_window,
}
local buffers = {
	surface.navigator_buffer,
	surface.navigator_frame_buffer,
	surface.editor_buffer,
	surface.editor_frame_buffer,
	surface.preview_buffer,
}
vim.cmd("q!")
h.eq(nil, editor._state(), ":q! clears the simplified workspace state")
vim.wait(1000, function()
	for _, window in ipairs(windows) do
		if vim.api.nvim_win_is_valid(window) then
			return false
		end
	end
	return true
end)
for _, window in ipairs(windows) do
	h.falsy(vim.api.nvim_win_is_valid(window), ":q! closes every simplified window")
end
for _, buffer in ipairs(buffers) do
	h.falsy(vim.api.nvim_buf_is_valid(buffer), ":q! deletes every simplified buffer")
end
h.eq(before, file_bytes(path), ":q! discards malformed simplified text without persistence")
