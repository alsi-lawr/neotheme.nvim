local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local editor = require("neotheme.palette_editor")
local engine = require("neotheme")
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

themes.create_family("session")
themes.clone("gruber-dark", "session", "override-theme")
local theme_file = vim.fs.joinpath(state.root(), "palettes", "session", "override-theme.json")
local before_bytes = table.concat(vim.fn.readfile(theme_file, "b"), "\n")

engine.setup({ theme = "gruber-dark-muted" })
engine.load()
engine.switch("override-theme")
h.eq("override-theme", engine.current().active_theme, "user theme becomes the session override")

vim.cmd.colorscheme("default")
h.eq({
	loaded = false,
	configured_theme = "gruber-dark-muted",
	session_override = true,
}, engine.current(), "external colorscheme unloads Neotheme but retains override intent")
h.truthy(
	engine._retains_session_theme("override-theme"),
	"unloaded engine retains the override theme reference"
)
local session_before = engine._snapshot_state()

require("neotheme.commands").register()
vim.cmd("NeothemePalette")
local surface = assert(editor._state())
move_navigator(surface, "session")
press("2")
surface = assert(editor._state())
move_navigator(surface, "user override-theme")

local original_input = vim.ui.input
local original_notify = vim.notify
local prompt
local message
vim.ui.input = function(options, callback)
	prompt = vim.deepcopy(options)
	callback("Y")
end
vim.notify = function(value, level)
	if level == vim.log.levels.ERROR then
		message = tostring(value)
	end
end
press("d")
vim.ui.input = original_input
vim.notify = original_notify

h.eq("delete? Y/n", prompt.prompt, "retained override deletion uses the confirmation path")
h.eq("Y", prompt.default, "retained override deletion confirmation defaults to Y")
h.truthy(
	message:find("session override theme", 1, true),
	"rejection identifies the retained reference"
)
h.truthy(message:find(":NeothemeReset", 1, true), "rejection gives an actionable release command")
h.eq(
	before_bytes,
	table.concat(vim.fn.readfile(theme_file, "b"), "\n"),
	"rejection preserves file bytes"
)
h.truthy(themes.is_user("override-theme"), "rejection preserves the registry entry")
h.truthy(
	vim.tbl_contains(select(2, themes.inventory()).session, "override-theme"),
	"rejection preserves manager inventory"
)
h.eq(session_before, engine._snapshot_state(), "rejection preserves retained session state")

vim.cmd("q!")
h.eq("override-theme", engine.reload(), "reload still resolves the retained override")
h.eq("override-theme", engine.current().active_theme, "reload restores the retained user theme")
h.eq(true, engine.current().session_override, "reload preserves override semantics")

h.eq("gruber-dark-muted", engine.reset(), "reset releases the retained override")
h.falsy(engine._retains_session_theme("override-theme"), "reset clears the retained reference")
themes.delete_theme("override-theme")
h.falsy(themes.is_user("override-theme"), "ordinary inactive unconfigured deletion remains allowed")
h.falsy(vim.uv.fs_stat(theme_file), "allowed deletion removes the palette file")
