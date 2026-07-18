local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local editor = require("neotheme.palette_editor")
local engine = require("neotheme")
local state = require("neotheme.state")
local themes = require("neotheme.themes")

vim.o.columns = 140
vim.o.lines = 40

local narrow_layout = assert(editor._layout(80, 23, 30))
h.eq(nil, editor._layout(80, 22, 30), "short layouts cannot clip protected role chrome")
h.eq(24, narrow_layout.navigator.width, "minimum layout keeps compact navigator")
h.eq(30, narrow_layout.editor.width, "minimum layout protects role editor width")
h.eq(18, narrow_layout.preview.width, "minimum layout retains code preview")
h.eq(20, narrow_layout.editor.height, "minimum layout fits complete Markup workspace")
local wide_layout = assert(editor._layout(140, 39, 30))
h.eq(36, wide_layout.editor.width, "wide layout expands role editor")

local function lines(buffer)
	return vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
end

local function find_line(buffer, expected)
	for index, line in ipairs(lines(buffer)) do
		if line == expected then
			return index
		end
	end
	error("missing workspace line: " .. expected)
end

local function find_containing_line(buffer, expected)
	for index, line in ipairs(lines(buffer)) do
		if line:find(expected, 1, true) then
			return index, line
		end
	end
	error("missing workspace text: " .. expected)
end

local function editor_chrome(surface)
	local frame_lines = lines(surface.editor_frame_buffer)
	local tab_count = surface.layout.editor.width < 32 and 4 or 3
	local tabs = vim.list_slice(frame_lines, 1, tab_count)
	local help = frame_lines[#frame_lines]
	local groups = {}
	local marks = vim.api.nvim_buf_get_extmarks(
		surface.editor_frame_buffer,
		surface.editor_chrome_namespace,
		0,
		-1,
		{ details = true }
	)
	for _, mark in ipairs(marks) do
		table.insert(groups, mark[4].hl_group)
	end
	return tabs, help, groups, frame_lines
end

local function press(key)
	vim.api.nvim_feedkeys(vim.keycode(key), "x", false)
end

local function capture_error(action)
	local original = vim.notify
	local messages = {}
	vim.notify = function(message, level)
		if level == vim.log.levels.ERROR then
			table.insert(messages, tostring(message))
		end
	end
	local ok, action_error = pcall(action)
	vim.notify = original
	if not ok then
		error(action_error)
	end
	return table.concat(messages, "\n")
end

local function move_navigator(surface, expected)
	vim.api.nvim_set_current_win(surface.navigator_window)
	vim.api.nvim_win_set_cursor(
		surface.navigator_window,
		{ find_containing_line(surface.navigator_buffer, expected), 0 }
	)
	vim.api.nvim_exec_autocmds("CursorMoved", {
		buffer = surface.navigator_buffer,
		modeline = false,
	})
end

local function replace_field(surface, field, value)
	local row = assert(surface.field_lines[field])
	local line = lines(surface.editor_buffer)[row + 1]
	local prefix = assert(line:match("^(.-=%s*)"))
	local replacement = prefix .. value
	vim.api.nvim_buf_set_lines(surface.editor_buffer, row, row + 1, false, { replacement })
	vim.api.nvim_exec_autocmds("TextChanged", { buffer = surface.editor_buffer, modeline = false })
	local column = value == "" and #replacement or assert(replacement:find(value, 1, true)) - 1
	return row, column
end

local function replace_background(surface, value)
	local row = assert(surface.metadata_line)
	local line = lines(surface.editor_buffer)[row + 1]
	local prefix = assert(line:match("^(.-=%s*)"))
	local replacement = prefix .. value
	vim.api.nvim_buf_set_lines(surface.editor_buffer, row, row + 1, false, { replacement })
	vim.api.nvim_exec_autocmds("TextChanged", { buffer = surface.editor_buffer, modeline = false })
	local column = value == "" and #replacement or assert(replacement:find(value, 1, true)) - 1
	return row, column
end

local function assert_closed(surface, label)
	vim.wait(1000, function()
		return not vim.api.nvim_win_is_valid(surface.navigator_window)
			and not vim.api.nvim_win_is_valid(surface.navigator_frame_window)
			and not vim.api.nvim_win_is_valid(surface.editor_window)
			and not vim.api.nvim_win_is_valid(surface.editor_frame_window)
			and not vim.api.nvim_win_is_valid(surface.preview_window)
	end)
	for _, field in ipairs({
		"navigator_window",
		"navigator_frame_window",
		"editor_window",
		"editor_frame_window",
		"preview_window",
	}) do
		h.falsy(vim.api.nvim_win_is_valid(surface[field]), label .. " closes " .. field)
	end
	for _, field in ipairs({
		"navigator_buffer",
		"navigator_frame_buffer",
		"editor_buffer",
		"editor_frame_buffer",
		"preview_buffer",
	}) do
		h.falsy(vim.api.nvim_buf_is_valid(surface[field]), label .. " closes " .. field)
	end
end

themes.create_family("studio")
themes.create_family("ocean")
themes.create_family("empty")
themes.clone("gruber-dark", "studio", "studio-night")
themes.clone("typeset-paper", "ocean", "ocean-paper")
require("neotheme.commands").register()

h.eq(2, vim.fn.exists(":NeothemePalette"), "palette command registers before load")
h.falsy(pcall(vim.cmd, "NeothemePalette one two"), "palette command rejects extra arguments")
h.truthy(
	vim.tbl_contains(vim.fn.getcompletion("NeothemePalette st", "cmdline"), "studio-night"),
	"palette completion includes enabled user themes"
)

vim.cmd("NeothemePalette studio-night")
local surface = assert(editor._state())
h.eq("workspace", surface.kind, "direct command opens integrated workspace")
h.eq(surface.editor_window, vim.api.nvim_get_current_win(), "direct user theme focuses role editor")
h.falsy(engine.current().loaded, "workspace opens before Neotheme is loaded")
h.falsy(vim.bo[surface.editor_buffer].modified, "initial role buffer is unmodified")
h.eq(
	false,
	vim.api.nvim_win_get_config(surface.preview_window).focusable,
	"preview is non-focusable"
)
h.truthy(surface.layout.navigator.col < surface.layout.editor.col, "navigator is left of editor")
h.truthy(surface.layout.editor.col < surface.layout.preview.col, "editor is left of preview")
h.eq(
	"  1 Families    2 Themes  ",
	lines(surface.navigator_frame_buffer)[1],
	"navigator uses browser tabs"
)
local initial_tabs, initial_help, initial_groups = editor_chrome(surface)
h.eq("  1 Surface  2 Text  3 Syntax", initial_tabs[1], "role tabs are protected chrome")
h.eq("C-h nav | C commit | q close", initial_help, "role help is protected chrome")
h.truthy(
	find_containing_line(surface.editor_buffer, "deepest = #"),
	"role editor uses direct fields"
)
h.truthy(
	find_containing_line(surface.editor_buffer, "background = dark"),
	"role editor exposes background metadata"
)
for _, line in ipairs(lines(surface.editor_buffer)) do
	h.falsy(line:find("{", 1, true), "role editor never exposes JSON tree braces")
end
h.eq(9, surface.token_count, "active Surface category colors every visible token")
local active_tabs = 0
local inactive_tabs = 0
for _, group in ipairs(initial_groups) do
	active_tabs = active_tabs + (group == "NeothemeBrowserTabActive" and 1 or 0)
	inactive_tabs = inactive_tabs + (group == "NeothemeBrowserTabInactive" and 1 or 0)
end
h.eq(1, active_tabs, "one role-category tab is active")
h.eq(6, inactive_tabs, "remaining role-category tabs are inactive")

local close_cases = {
	{ panel = "role editor", key = "q" },
	{ panel = "role editor", key = "<Esc>" },
	{ panel = "navigator", key = "q" },
	{ panel = "navigator", key = "<Esc>" },
}
for index, case in ipairs(close_cases) do
	if index > 1 then
		editor.edit("studio-night")
		surface = assert(editor._state())
	end
	if case.panel == "navigator" then
		press("<C-h>")
	end
	local clean_surface = vim.deepcopy(assert(editor._state()))
	press(case.key)
	h.eq(nil, editor._state(), case.panel .. " " .. case.key .. " closes a clean workspace")
	assert_closed(clean_surface, case.panel .. " " .. case.key .. " clean close")
end

for _, case in ipairs(close_cases) do
	editor.edit("studio-night")
	surface = assert(editor._state())
	replace_field(surface, "base", "#010203")
	surface = assert(editor._state())
	local dirty_lines = lines(surface.editor_buffer)
	local dirty_record = vim.deepcopy(surface.record)
	local dirty_preview = vim.api.nvim_get_hl(surface.preview_namespace, { name = "Normal" })
	if case.panel == "navigator" then
		press("<C-h>")
	end
	local message = capture_error(function()
		press(case.key)
	end)
	local retained = assert(editor._state())
	h.eq(
		"neotheme: modified palette; use C or :write to save, or :q! to discard and close",
		message,
		case.panel .. " " .. case.key .. " reports exact dirty close guidance"
	)
	h.eq(
		surface.editor_buffer,
		retained.editor_buffer,
		case.panel .. " dirty close keeps workspace"
	)
	h.eq(dirty_lines, lines(retained.editor_buffer), case.panel .. " dirty close retains text")
	h.eq(dirty_record, retained.record, case.panel .. " dirty close retains model")
	h.eq(
		dirty_preview,
		vim.api.nvim_get_hl(retained.preview_namespace, { name = "Normal" }),
		case.panel .. " dirty close retains preview"
	)
	h.truthy(retained.dirty, case.panel .. " " .. case.key .. " preserves dirty state")
	local discarded = vim.deepcopy(retained)
	vim.api.nvim_set_current_win(retained.editor_window)
	vim.cmd("q!")
	h.eq(nil, editor._state(), case.panel .. " dirty fixture can still be discarded")
	assert_closed(discarded, case.panel .. " " .. case.key .. " dirty discard")
end

h.load()
local global_contract = {
	colors_name = vim.g.colors_name,
	background = vim.o.background,
	normal = h.highlight("Normal"),
	terminal_background = vim.g.terminal_color_background,
	current = engine.current(),
	config = require("neotheme.config").get(),
	lualine = package.loaded["neotheme.lualine"],
}
editor.edit("studio-night")
surface = assert(editor._state())
replace_field(surface, "base", "#0a0b0c")
surface = assert(editor._state())
h.eq(
	0x0a0b0c,
	vim.api.nvim_get_hl(surface.preview_namespace, { name = "Normal" }).bg,
	"surface base edit updates preview Normal"
)
local preview_winhighlight =
	vim.api.nvim_get_option_value("winhighlight", { win = surface.preview_window })
local mapped_preview_normal = assert(preview_winhighlight:match("Normal:([^,]+)"))
h.eq(
	0x0a0b0c,
	vim.api.nvim_get_hl(surface.preview_namespace, { name = mapped_preview_normal }).bg,
	"preview chrome derives mapped background from preview namespace"
)
local empty_row, empty_col = replace_field(surface, "base", "")
surface = assert(editor._state())
local empty_diagnostics =
	vim.diagnostic.get(surface.editor_buffer, { namespace = surface.diagnostic_namespace })
h.eq(empty_row, empty_diagnostics[1].lnum, "empty color diagnostic uses field line")
h.eq(empty_col, empty_diagnostics[1].col, "empty color diagnostic uses insertion point")
h.truthy(empty_diagnostics[1].col > 0, "empty color diagnostic never falls back to column zero")
h.eq(
	0x0a0b0c,
	vim.api.nvim_get_hl(surface.preview_namespace, { name = "NeothemeBrowserFloat" }).bg,
	"empty color retains last valid preview chrome"
)
replace_field(surface, "base", "#0a0b0c")

local background_preview = surface.preview_background
local metadata_row, metadata_col = replace_background(surface, "sepia")
surface = assert(editor._state())
local metadata_diagnostics =
	vim.diagnostic.get(surface.editor_buffer, { namespace = surface.diagnostic_namespace })
h.eq(metadata_row, metadata_diagnostics[1].lnum, "invalid background diagnostic uses metadata row")
h.eq(metadata_col, metadata_diagnostics[1].col, "invalid background diagnostic uses value range")
h.truthy(
	metadata_diagnostics[1].message:find("background must be dark or light", 1, true),
	"invalid background diagnostic explains accepted metadata"
)
h.eq(background_preview, surface.preview_background, "invalid background retains preview semantics")
press("]")
h.eq("surface", editor._state().category, "invalid background blocks category movement")
h.falsy(pcall(vim.cmd, "write"), "invalid background blocks write")
replace_background(surface, "light")
surface = assert(editor._state())
h.eq("light", surface.record.background, "valid background updates in-memory metadata")
h.eq("light", surface.preview_background, "valid background updates preview semantics")
h.truthy(
	vim.inspect(vim.api.nvim_win_get_config(surface.preview_window).title):find("light"),
	"preview title exposes active background semantics"
)
press("]")
surface = assert(editor._state())
h.eq("text", surface.category, "right bracket selects next role category")
h.truthy(
	find_containing_line(surface.editor_buffer, "primary = #"),
	"Text category replaces fields"
)
press("7")
surface = assert(editor._state())
h.eq("ui", surface.category, "numeric category mapping selects UI")

local preview_before = vim.api.nvim_get_hl(surface.preview_namespace, { name = "Normal" })
local valid_before = vim.deepcopy(surface.last_valid)
local invalid_row, invalid_col = replace_field(surface, "accent", "#123")
surface = assert(editor._state())
h.truthy(surface.dirty, "invalid role edit marks workspace dirty")
h.eq(valid_before, surface.last_valid, "invalid role edit retains complete last valid palette")
h.eq(
	preview_before,
	vim.api.nvim_get_hl(surface.preview_namespace, { name = "Normal" }),
	"invalid edit retains preview"
)
local diagnostics =
	vim.diagnostic.get(surface.editor_buffer, { namespace = surface.diagnostic_namespace })
h.eq(1, #diagnostics, "invalid role has one diagnostic")
h.eq(invalid_row, diagnostics[1].lnum, "diagnostic uses field line")
h.eq(invalid_col, diagnostics[1].col, "diagnostic starts at invalid value")
h.eq(invalid_col + 4, diagnostics[1].end_col, "diagnostic covers invalid value")
h.truthy(
	diagnostics[1].message:find("palette.ui.accent must be a #RRGGBB color", 1, true),
	"diagnostic identifies semantic role"
)
press("[")
h.eq("ui", editor._state().category, "invalid edit blocks category movement")
press("<C-h>")
h.eq(surface.editor_window, vim.api.nvim_get_current_win(), "invalid edit blocks panel movement")
h.falsy(pcall(vim.cmd, "write"), "invalid edit blocks write")
h.truthy(vim.bo[surface.editor_buffer].modified, "blocked write preserves dirty state")
h.falsy(pcall(vim.cmd, "q"), "normal q refuses a dirty role editor")
h.truthy(vim.api.nvim_win_is_valid(surface.editor_window), "failed dirty q keeps workspace open")

replace_field(surface, "accent", "#112233")
surface = assert(editor._state())
h.eq(
	{},
	vim.diagnostic.get(surface.editor_buffer, { namespace = surface.diagnostic_namespace }),
	"valid fix clears diagnostic"
)
h.eq("#112233", surface.record.palette.ui.accent, "valid edit updates complete in-memory palette")
local token_group = "NeothemePaletteToken112233"
local token_highlight = vim.api.nvim_get_hl(surface.editor_namespace, { name = token_group })
h.eq(0x112233, token_highlight.bg, "visible token uses edited color background")
h.eq(0xffffff, token_highlight.fg, "visible token uses readable foreground")
press("1")
surface = assert(editor._state())
h.eq("surface", surface.category, "category movement succeeds after valid fix")
h.eq("#112233", surface.record.palette.ui.accent, "category switch retains other role edits")
h.truthy(surface.dirty, "category switch preserves native dirty state")
local dirty_editor = surface.editor_buffer
vim.cmd("NeothemePalette")
surface = assert(editor._state())
h.eq(dirty_editor, surface.editor_buffer, "duplicate workspace command preserves dirty editor")
h.eq(
	surface.navigator_window,
	vim.api.nvim_get_current_win(),
	"duplicate command focuses navigator"
)
h.truthy(surface.dirty, "duplicate command does not discard dirty role edits")
press("<C-l>")
vim.cmd("write")
h.falsy(vim.bo[surface.editor_buffer].modified, "write clears dirty state")
h.eq("#112233", themes.get("studio-night").ui.accent, "write persists complete record atomically")
h.eq("#0a0b0c", themes.get("studio-night").surface.base, "write persists edited preview surface")
h.eq("light", themes.background("studio-night"), "write persists background metadata")
h.eq(global_contract, {
	colors_name = vim.g.colors_name,
	background = vim.o.background,
	normal = h.highlight("Normal"),
	terminal_background = vim.g.terminal_color_background,
	current = engine.current(),
	config = require("neotheme.config").get(),
	lualine = package.loaded["neotheme.lualine"],
}, "editing and preview preserve global theme contract")
local saved = vim.deepcopy(surface)
vim.cmd("q")
h.eq(nil, editor._state(), "saved workspace closes normally")
assert_closed(saved, "saved workspace")

editor.edit("studio-night")
surface = assert(editor._state())
press("5")
surface = assert(editor._state())
h.eq("markup", surface.category, "wide workspace opens Markup category")
vim.o.columns = 80
vim.o.lines = 24
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
surface = assert(editor._state())
h.eq(30, surface.layout.editor.width, "wide-to-narrow resize uses minimum role width")
h.eq(
	"  1 Families  2 Themes",
	lines(surface.navigator_frame_buffer)[1],
	"narrow navigator rerenders tabs"
)
for _, help in ipairs({
	"Enter themes  C commit",
	"a add family  d delete",
	"v visibility  q close",
}) do
	local _, line = find_containing_line(surface.navigator_frame_buffer, help)
	h.truthy(
		vim.fn.strdisplaywidth(line) <= surface.layout.navigator.width,
		"minimum navigator keeps action help visible: " .. help
	)
end
local narrow_role_lines = lines(surface.editor_buffer)
h.eq(15, #narrow_role_lines, "Markup buffer contains only metadata and role fields")
h.truthy(narrow_role_lines[1]:find("background = ", 1, true), "metadata is the first editable line")
for index, line in ipairs(narrow_role_lines) do
	local editable = index == 1 and line:match("^background = ")
		or line:match("^[%w_]+ = #%x%x%x%x%x%x$")
	h.truthy(editable, "role buffer excludes editable workspace chrome")
end
local narrow_tabs, narrow_help, _, frame_lines = editor_chrome(surface)
h.eq("  1 Surface  2 Text", narrow_tabs[1], "narrow role panel rerenders protected tabs")
local tab_text = table.concat(narrow_tabs, " ")
for _, label in ipairs({
	"Surface",
	"Text",
	"Syntax",
	"Diagnostic",
	"Markup",
	"Version control",
	"UI",
}) do
	h.truthy(tab_text:find(label, 1, true), "minimum layout keeps category tab " .. label)
end
local markup_fields = 0
for _, line in ipairs(narrow_role_lines) do
	markup_fields = markup_fields + (line:find(" = #", 1, true) and 1 or 0)
end
h.eq(14, markup_fields, "minimum layout retains every Markup field")
h.eq("C-h nav | C commit | q close", narrow_help, "minimum layout retains protected help")
h.truthy(
	vim.fn.strdisplaywidth(narrow_help) <= surface.layout.editor.width,
	"minimum role help fits without clipping"
)
local visible = vim.api.nvim_win_call(surface.editor_window, function()
	local view = vim.fn.winsaveview()
	return { topline = view.topline, first = vim.fn.line("w0"), last = vim.fn.line("w$") }
end)
h.eq(1, visible.topline, "minimum viewport starts at metadata")
h.eq(1, visible.first, "minimum viewport shows first editable line")
h.eq(#narrow_role_lines, visible.last, "minimum viewport shows final Markup field")
h.eq(
	15,
	vim.api.nvim_win_get_height(surface.editor_window),
	"minimum content inset fits all editable lines"
)
local frame_visible = vim.api.nvim_win_call(surface.editor_frame_window, function()
	local view = vim.fn.winsaveview()
	return { topline = view.topline, first = vim.fn.line("w0"), last = vim.fn.line("w$") }
end)
h.eq(1, frame_visible.topline, "protected role frame starts at category tabs")
h.eq(1, frame_visible.first, "protected role frame shows first tab row")
h.eq(#frame_lines, frame_visible.last, "protected role frame shows help row")
h.eq(surface.layout.editor.height, #frame_lines, "protected role frame fills viewport")
h.falsy(vim.bo[surface.editor_frame_buffer].modifiable, "role chrome buffer is not modifiable")
h.eq(
	surface.layout.editor.height,
	#narrow_tabs + #narrow_role_lines + 1,
	"minimum viewport simultaneously fits tabs, metadata, fields, and help"
)
h.eq(
	surface.field_lines.checked + 1,
	vim.api.nvim_win_get_cursor(surface.editor_window)[1],
	"minimum layout places cursor at first active field"
)
local original_metadata = narrow_role_lines[1]
vim.api.nvim_win_set_cursor(surface.editor_window, { 1, 0 })
local edit_ok, edit_error = pcall(function()
	vim.cmd("normal! x")
	vim.api.nvim_exec_autocmds("TextChanged", {
		buffer = surface.editor_buffer,
		modeline = false,
	})
end)
h.truthy(edit_ok, "normal editing beside protected chrome never raises: " .. tostring(edit_error))
h.truthy(
	vim.diagnostic
		.get(surface.editor_buffer, { namespace = surface.diagnostic_namespace })[1].message
		:find("expected background metadata", 1, true),
	"structural content corruption receives a diagnostic"
)
vim.api.nvim_buf_set_lines(surface.editor_buffer, 0, 1, false, { original_metadata })
vim.api.nvim_exec_autocmds("TextChanged", { buffer = surface.editor_buffer, modeline = false })
vim.bo[surface.editor_buffer].modified = false
h.eq(
	{},
	vim.diagnostic.get(surface.editor_buffer, { namespace = surface.diagnostic_namespace }),
	"repair after structural edit restores valid workspace"
)

local function assert_structure_rejected(label, mutate, message)
	local valid_lines = lines(surface.editor_buffer)
	local valid_record = vim.deepcopy(assert(editor._state()).record)
	local valid_preview = vim.api.nvim_get_hl(surface.preview_namespace, { name = "Normal" })
	local persisted_palette = vim.deepcopy(themes.get("studio-night"))
	local persisted_background = themes.background("studio-night")
	local expected_row = mutate(surface.editor_buffer, valid_lines)
	vim.api.nvim_exec_autocmds("TextChanged", {
		buffer = surface.editor_buffer,
		modeline = false,
	})
	surface = assert(editor._state())
	local rejected_lines = lines(surface.editor_buffer)
	local diagnostics =
		vim.diagnostic.get(surface.editor_buffer, { namespace = surface.diagnostic_namespace })
	h.eq(1, #diagnostics, label .. " has one structural diagnostic")
	h.eq(expected_row, diagnostics[1].lnum, label .. " diagnostic uses offending row")
	h.truthy(
		diagnostics[1].end_col > diagnostics[1].col or diagnostics[1].col > 0,
		label .. " diagnostic uses field range or insertion column"
	)
	h.truthy(diagnostics[1].message:find(message, 1, true), label .. " diagnostic is precise")
	h.eq(valid_record, surface.record, label .. " retains last valid model")
	h.eq(
		valid_preview,
		vim.api.nvim_get_hl(surface.preview_namespace, { name = "Normal" }),
		label .. " retains last valid preview"
	)
	h.truthy(vim.bo[surface.editor_buffer].modified, label .. " remains dirty")

	press("7")
	h.eq("markup", editor._state().category, label .. " blocks category movement")
	h.eq(rejected_lines, lines(surface.editor_buffer), label .. " category movement retains text")
	press("<C-h>")
	h.eq(surface.editor_window, vim.api.nvim_get_current_win(), label .. " blocks panel movement")
	h.eq(rejected_lines, lines(surface.editor_buffer), label .. " panel movement retains text")
	h.falsy(pcall(vim.cmd, "NeothemePalette ocean-paper"), label .. " blocks theme movement")
	h.eq(rejected_lines, lines(surface.editor_buffer), label .. " theme movement retains text")
	h.falsy(pcall(vim.cmd, "write"), label .. " blocks write")
	h.truthy(vim.bo[surface.editor_buffer].modified, label .. " blocked write remains dirty")
	h.eq(rejected_lines, lines(surface.editor_buffer), label .. " blocked write retains text")
	h.eq(persisted_palette, themes.get("studio-night"), label .. " write does not persist")
	h.eq(
		persisted_background,
		themes.background("studio-night"),
		label .. " write does not persist metadata"
	)

	vim.api.nvim_buf_set_lines(surface.editor_buffer, 0, -1, false, valid_lines)
	vim.api.nvim_exec_autocmds("TextChanged", {
		buffer = surface.editor_buffer,
		modeline = false,
	})
	vim.bo[surface.editor_buffer].modified = false
	surface = assert(editor._state())
	h.eq(
		{},
		vim.diagnostic.get(surface.editor_buffer, { namespace = surface.diagnostic_namespace }),
		label .. " repair restores valid structure"
	)
end

assert_structure_rejected("trailing unknown row", function(buffer)
	local row = vim.api.nvim_buf_line_count(buffer)
	vim.api.nvim_buf_set_lines(buffer, row, row, false, { "trailing = #123456" })
	return row
end, "unknown field markup.trailing")

assert_structure_rejected("duplicate row", function(buffer, valid_lines)
	vim.api.nvim_buf_set_lines(buffer, 2, 2, false, { valid_lines[2] })
	return 2
end, "duplicate field markup.checked")

assert_structure_rejected("missing row", function(buffer, valid_lines)
	vim.api.nvim_buf_set_lines(buffer, #valid_lines - 1, #valid_lines, false, {})
	return #valid_lines - 2
end, "missing field markup.unchecked after this row")

assert_structure_rejected("reordered rows", function(buffer, valid_lines)
	vim.api.nvim_buf_set_lines(buffer, 1, 3, false, { valid_lines[3], valid_lines[2] })
	return 1
end, "field markup.checked is out of order")

press("7")
h.eq("ui", editor._state().category, "minimum layout category tabs remain usable")
press("5")
h.eq("markup", editor._state().category, "minimum layout can return to Markup")
vim.o.columns = 140
vim.o.lines = 40
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
surface = assert(editor._state())
h.eq(36, surface.layout.editor.width, "narrow-to-wide resize restores wide role panel")
local wide_tabs = editor_chrome(surface)
h.eq("  1 Surface  2 Text  3 Syntax", wide_tabs[1], "wide resize rerenders wide category tabs")

local before_invalid_resize = lines(surface.editor_buffer)
local resize_record = vim.deepcopy(surface.record)
local resize_last_valid = vim.deepcopy(surface.last_valid)
local resize_preview = vim.api.nvim_get_hl(surface.preview_namespace, { name = "Normal" })
local resize_preview_background = surface.preview_background
local resize_persisted = vim.deepcopy(themes.get("studio-night"))
local trailing_row = vim.api.nvim_buf_line_count(surface.editor_buffer)
vim.api.nvim_buf_set_lines(
	surface.editor_buffer,
	trailing_row,
	trailing_row,
	false,
	{ "resize_unknown = #123456" }
)
vim.api.nvim_exec_autocmds("TextChanged", {
	buffer = surface.editor_buffer,
	modeline = false,
})
surface = assert(editor._state())
local malformed_resize_text = lines(surface.editor_buffer)
local resize_diagnostics =
	vim.diagnostic.get(surface.editor_buffer, { namespace = surface.diagnostic_namespace })
h.eq(1, #resize_diagnostics, "wide invalid workspace has one diagnostic")
h.eq(trailing_row, resize_diagnostics[1].lnum, "wide invalid diagnostic uses surplus row")
h.truthy(surface.dirty, "wide invalid workspace is dirty before resize")

vim.o.columns = 80
vim.o.lines = 24
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
surface = assert(editor._state())
local invalid_narrow_tabs, invalid_narrow_help, _, invalid_frame_lines = editor_chrome(surface)
h.eq(30, surface.layout.editor.width, "invalid resize adopts narrow role geometry")
h.eq("  1 Surface  2 Text", invalid_narrow_tabs[1], "invalid resize adopts compact tabs")
h.eq(4, #invalid_narrow_tabs, "invalid resize renders all compact tab rows")
h.eq("C-h nav | C commit | q close", invalid_narrow_help, "invalid resize retains protected help")
local invalid_frame_view = vim.api.nvim_win_call(surface.editor_frame_window, function()
	local view = vim.fn.winsaveview()
	return { topline = view.topline, first = vim.fn.line("w0"), last = vim.fn.line("w$") }
end)
h.eq(1, invalid_frame_view.topline, "invalid narrow frame starts at compact tabs")
h.eq(1, invalid_frame_view.first, "invalid narrow frame displays first tab row")
h.eq(
	#invalid_frame_lines,
	invalid_frame_view.last,
	"invalid narrow frame displays protected help row"
)
h.eq(
	invalid_narrow_help,
	invalid_frame_lines[invalid_frame_view.last],
	"invalid narrow help is in the actual viewport"
)
h.eq(
	malformed_resize_text,
	lines(surface.editor_buffer),
	"invalid resize retains exact malformed text"
)
h.eq(resize_record, surface.record, "invalid resize retains model")
h.eq(resize_last_valid, surface.last_valid, "invalid resize retains last valid model")
h.eq(
	resize_preview,
	vim.api.nvim_get_hl(surface.preview_namespace, { name = "Normal" }),
	"invalid resize retains preview"
)
h.eq(
	resize_preview_background,
	surface.preview_background,
	"invalid resize retains preview metadata"
)
h.eq(
	resize_diagnostics,
	vim.diagnostic.get(surface.editor_buffer, { namespace = surface.diagnostic_namespace }),
	"invalid resize retains diagnostic"
)
h.truthy(surface.dirty, "invalid resize retains dirty state")

press("7")
h.eq("markup", editor._state().category, "invalid resized workspace blocks category movement")
h.eq(malformed_resize_text, lines(surface.editor_buffer), "blocked category retains malformed text")
press("<C-h>")
h.eq(
	surface.editor_window,
	vim.api.nvim_get_current_win(),
	"invalid resized workspace blocks panel movement"
)
h.falsy(
	pcall(vim.cmd, "NeothemePalette ocean-paper"),
	"invalid resized workspace blocks theme movement"
)
h.falsy(pcall(vim.cmd, "write"), "invalid resized workspace blocks write")
h.truthy(vim.bo[surface.editor_buffer].modified, "invalid resized blocked write remains dirty")
h.eq(
	malformed_resize_text,
	lines(surface.editor_buffer),
	"blocked operations retain malformed text"
)
h.eq(resize_persisted, themes.get("studio-night"), "invalid resized write does not persist")

vim.api.nvim_buf_set_lines(surface.editor_buffer, 0, -1, false, before_invalid_resize)
vim.api.nvim_exec_autocmds("TextChanged", {
	buffer = surface.editor_buffer,
	modeline = false,
})
vim.bo[surface.editor_buffer].modified = false
surface = assert(editor._state())
h.eq(
	{},
	vim.diagnostic.get(surface.editor_buffer, { namespace = surface.diagnostic_namespace }),
	"repair after invalid resize restores workspace"
)
local repaired_resize = vim.deepcopy(surface)
vim.cmd("q")
h.eq(nil, editor._state(), "repaired resized workspace clears active state")
assert_closed(repaired_resize, "repaired resized workspace")

local malformed = vim.fs.joinpath(state.root(), "palettes", "studio", "malformed.json")
vim.fn.writefile({ "{ malformed" }, malformed)
vim.cmd("NeothemePalette")
surface = assert(editor._state())
h.eq(
	surface.navigator_window,
	vim.api.nvim_get_current_win(),
	"no-argument command focuses navigator"
)
h.eq("families", surface.navigator_mode, "workspace starts on Families tab")
h.truthy(
	find_containing_line(surface.navigator_buffer, "[x] empty"),
	"empty family remains visible"
)
h.truthy(
	find_containing_line(surface.navigator_buffer, "State diagnostics"),
	"navigator surfaces state diagnostics"
)
press("<C-l>")
h.eq(surface.editor_window, vim.api.nvim_get_current_win(), "Control-l focuses role editor")
press("<C-h>")
h.eq(surface.navigator_window, vim.api.nvim_get_current_win(), "Control-h returns to navigator")

press("<Tab>")
h.eq("themes", editor._state().navigator_mode, "Tab switches to Themes")
press("<S-Tab>")
h.eq("families", editor._state().navigator_mode, "Shift-Tab switches to Families")
move_navigator(surface, "[x] studio")
surface = assert(editor._state())
h.eq("studio", surface.selected_family, "family cursor movement updates selection")
press("<Tab>")
surface = assert(editor._state())
move_navigator(surface, "user studio-night")
surface = assert(editor._state())
h.eq("studio-night", surface.selected_theme, "theme cursor movement updates selection")
h.truthy(
	vim.inspect(vim.api.nvim_win_get_config(surface.preview_window).title):find("studio%-night"),
	"selector movement updates private preview title"
)
h.eq(global_contract, {
	colors_name = vim.g.colors_name,
	background = vim.o.background,
	normal = h.highlight("Normal"),
	terminal_background = vim.g.terminal_color_background,
	current = engine.current(),
	config = require("neotheme.config").get(),
	lualine = package.loaded["neotheme.lualine"],
}, "selector preview remains private")

press("<CR>")
surface = assert(editor._state())
h.eq("studio-night", surface.theme, "Enter selects an exact user theme")
h.eq(surface.editor_window, vim.api.nvim_get_current_win(), "user selection focuses role editor")
press("<C-h>")
surface = assert(editor._state())

local original_input = vim.ui.input
vim.ui.input = function(_, callback)
	callback("studio-copy")
end
press("c")
vim.ui.input = original_input
surface = assert(editor._state())
h.eq("studio-copy", surface.theme, "navigator clone opens new user palette")
h.eq(
	surface.editor_window,
	vim.api.nvim_get_current_win(),
	"clone transitions focus to role editor"
)
h.eq(
	themes.get("studio-night"),
	themes.get("studio-copy"),
	"user-theme clone copies complete palette"
)

press("<C-h>")
surface = assert(editor._state())
h.eq(surface.navigator_window, vim.api.nvim_get_current_win(), "Control-h focuses navigator")
h.eq("studio-copy", surface.theme, "panel focus does not discard selected user theme")
if surface.navigator_mode ~= "families" then
	press("<S-Tab>")
end
surface = assert(editor._state())
move_navigator(surface, "[x] studio")
press("v")
h.falsy(themes.family_enabled("studio"), "navigator toggles family visibility")
h.truthy(
	find_containing_line(surface.navigator_buffer, "[ ] studio"),
	"disabled family remains visible"
)
h.falsy(vim.tbl_contains(themes.families(), "studio"), "disabled family leaves public inventory")
press("v")
h.truthy(themes.family_enabled("studio"), "visibility can be restored")

local family_input = vim.ui.input
vim.ui.input = function(_, callback)
	callback("new-empty")
end
press("a")
vim.ui.input = family_input
h.truthy(themes.family_exists("new-empty"), "navigator creates family")
h.truthy(
	find_containing_line(surface.navigator_buffer, "[x] new-empty"),
	"new empty family is visible"
)
h.falsy(
	vim.tbl_contains(themes.families(), "new-empty"),
	"empty family stays out of public inventory"
)

local forced = vim.deepcopy(assert(editor._state()))
vim.api.nvim_set_current_win(forced.editor_window)
replace_field(forced, "deepest", "#010203")
vim.cmd("q!")
h.eq(nil, editor._state(), "q! discards dirty workspace")
assert_closed(forced, "forced workspace")

local direct_input = vim.ui.input
local direct_answers = { "studio", "bundle-copy" }
vim.ui.input = function(_, callback)
	callback(table.remove(direct_answers, 1))
end
vim.cmd("NeothemePalette gruber-dark")
vim.ui.input = direct_input
h.eq("bundle-copy", editor._state().theme, "bundled command argument follows clone flow")
vim.cmd("q!")
