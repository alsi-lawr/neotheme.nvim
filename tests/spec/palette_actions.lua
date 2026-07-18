local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local editor = require("neotheme.palette_editor")
local engine = require("neotheme")
local palette = require("neotheme.palette")
local state = require("neotheme.state")
local themes = require("neotheme.themes")

vim.o.columns = 140
vim.o.lines = 40

local function lines(buffer)
	return vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
end

local function contains_line(buffer, expected)
	for index, line in ipairs(lines(buffer)) do
		if line:find(expected, 1, true) then
			return index, line
		end
	end
	error("missing workspace text: " .. expected)
end

local function press(key)
	vim.api.nvim_feedkeys(vim.keycode(key), "x", false)
end

local function has_buffer_map(buffer, lhs)
	for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buffer, "n")) do
		if mapping.lhs == lhs then
			return true
		end
	end
	return false
end

local function move_navigator(surface, expected)
	vim.api.nvim_set_current_win(surface.navigator_window)
	vim.api.nvim_win_set_cursor(
		surface.navigator_window,
		{ contains_line(surface.navigator_buffer, expected), 0 }
	)
	vim.api.nvim_exec_autocmds("CursorMoved", {
		buffer = surface.navigator_buffer,
		modeline = false,
	})
end

local function answer(value, action)
	local original = vim.ui.input
	local seen
	vim.ui.input = function(options, callback)
		seen = vim.deepcopy(options)
		if value == "default" then
			callback(options.default)
		elseif value == "cancel" then
			callback(nil)
		else
			callback(value)
		end
	end
	local ok, action_error = pcall(action)
	vim.ui.input = original
	if not ok then
		error(action_error)
	end
	return seen
end

local function choose(value, action)
	local original = vim.ui.select
	local seen
	vim.ui.select = function(items, options, callback)
		seen = { items = vim.deepcopy(items), options = vim.deepcopy(options) }
		callback(value)
	end
	local ok, action_error = pcall(action)
	vim.ui.select = original
	if not ok then
		error(action_error)
	end
	return seen
end

local workspace_window_fields = {
	"navigator_frame_window",
	"navigator_window",
	"editor_frame_window",
	"editor_window",
	"preview_window",
}

local function open_provider_input(options, label)
	local surface = assert(editor._state())
	local return_window = vim.api.nvim_get_current_win()
	local buffer = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { options.prompt .. (options.default or "") })
	local width = math.min(40, vim.o.columns - 4)
	local window = vim.api.nvim_open_win(buffer, true, {
		relative = "editor",
		row = 2,
		col = math.floor((vim.o.columns - width) / 2),
		width = width,
		height = 1,
		style = "minimal",
		border = "rounded",
		focusable = true,
		zindex = 50,
	})
	local provider_config = vim.api.nvim_win_get_config(window)
	h.truthy(vim.api.nvim_win_is_valid(window), label .. " provider window is visible")
	h.falsy(provider_config.hide, label .. " provider window is not hidden")
	h.eq(true, provider_config.focusable, label .. " provider window is focusable")
	h.eq(window, vim.api.nvim_get_current_win(), label .. " provider window receives focus")
	h.eq(50, provider_config.zindex, label .. " provider uses Dressing's default layer")
	for _, field in ipairs(workspace_window_fields) do
		local workspace_zindex = vim.api.nvim_win_get_config(surface[field]).zindex
		h.truthy(workspace_zindex < provider_config.zindex, label .. " provider is above " .. field)
	end
	h.truthy(
		vim.api.nvim_win_get_config(surface.navigator_frame_window).zindex
			< vim.api.nvim_win_get_config(surface.navigator_window).zindex,
		label .. " navigator frame stays below its inset"
	)
	h.truthy(
		vim.api.nvim_win_get_config(surface.editor_frame_window).zindex
			< vim.api.nvim_win_get_config(surface.editor_window).zindex,
		label .. " role frame stays below its inset"
	)
	h.eq(
		vim.api.nvim_win_get_config(surface.navigator_frame_window).zindex,
		vim.api.nvim_win_get_config(surface.preview_window).zindex,
		label .. " preview uses the frame layer"
	)
	return {
		buffer = buffer,
		window = window,
		return_window = return_window,
	}
end

local function close_provider_input(modal)
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

local function provider_answer(value, action, label)
	local original = vim.ui.input
	local seen
	local modal
	vim.ui.input = function(options, callback)
		seen = vim.deepcopy(options)
		modal = open_provider_input(options, label)
		close_provider_input(modal)
		callback(value)
	end
	local ok, action_error = pcall(action)
	vim.ui.input = original
	if not ok then
		error(action_error)
	end
	h.truthy(modal, label .. " opens through vim.ui.input")
	h.falsy(vim.api.nvim_win_is_valid(modal.window), label .. " provider window cleans up")
	h.falsy(vim.api.nvim_buf_is_valid(modal.buffer), label .. " provider buffer cleans up")
	return seen
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

local function replace_field(surface, field, value)
	local row = assert(surface.field_lines[field])
	local line = lines(surface.editor_buffer)[row + 1]
	local replacement = assert(line:match("^(.-=%s*)")) .. value
	vim.api.nvim_buf_set_lines(surface.editor_buffer, row, row + 1, false, { replacement })
	vim.api.nvim_exec_autocmds("TextChanged", {
		buffer = surface.editor_buffer,
		modeline = false,
	})
end

local function record_path(family, theme)
	return vim.fs.joinpath(state.root(), "palettes", family, theme .. ".json")
end

local function family_path(family)
	return vim.fs.joinpath(state.root(), "families", family .. ".json")
end

local function file_bytes(path)
	return table.concat(vim.fn.readfile(path, "b"), "\n")
end

local function luminance(color)
	local function channel(value)
		value = value / 255
		return value <= 0.03928 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4
	end
	local red = math.floor(color / 0x10000) % 0x100
	local green = math.floor(color / 0x100) % 0x100
	local blue = color % 0x100
	return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
end

local function contrast_ratio(foreground, background)
	local foreground_luminance = luminance(foreground)
	local background_luminance = luminance(background)
	local light = math.max(foreground_luminance, background_luminance)
	local dark = math.min(foreground_luminance, background_luminance)
	return (light + 0.05) / (dark + 0.05)
end

local preview_contrast_pairs = {
	{ group = "CurSearch", foreground = "text.on_accent", background = "ui.current_search" },
	{ group = "Cursor", foreground = "text.on_accent", background = "ui.cursor" },
	{ group = "ErrorMsg", foreground = "text.on_error", background = "surface.error" },
	{ group = "IncSearch", foreground = "text.on_accent", background = "ui.match" },
	{
		group = "Substitute",
		foreground = "text.on_error",
		background = "version_control.conflict",
	},
	{ group = "MatchParen", foreground = "text.on_accent", background = "ui.match" },
	{ group = "Search", foreground = "text.on_accent", background = "ui.search" },
	{
		group = "SnippetTabstopActive",
		foreground = "text.on_accent",
		background = "ui.accent",
	},
	{
		group = "StatusLineTerm",
		foreground = "text.on_accent",
		background = "diagnostic.success",
	},
	{ group = "WildMenu", foreground = "text.on_accent", background = "ui.accent" },
	{
		group = "RedrawDebugClear",
		foreground = "text.on_accent",
		background = "diagnostic.warning",
	},
	{
		group = "RedrawDebugComposed",
		foreground = "text.on_accent",
		background = "diagnostic.success",
	},
	{
		group = "RedrawDebugRecompose",
		foreground = "text.on_accent",
		background = "diagnostic.error",
	},
	{
		group = "LspReferenceTarget",
		foreground = "text.on_accent",
		background = "ui.accent",
	},
}

local semantic_contrast_pairs = {
	{ foreground = "text.on_accent", background = "ui.current_search" },
	{ foreground = "text.on_accent", background = "ui.cursor" },
	{ foreground = "text.on_accent", background = "ui.match" },
	{ foreground = "text.on_accent", background = "ui.search" },
	{ foreground = "text.on_accent", background = "ui.accent" },
	{ foreground = "text.on_accent", background = "ui.directory" },
	{ foreground = "text.on_accent", background = "diagnostic.error" },
	{ foreground = "text.on_accent", background = "diagnostic.warning" },
	{ foreground = "text.on_accent", background = "diagnostic.information" },
	{ foreground = "text.on_accent", background = "diagnostic.hint" },
	{ foreground = "text.on_accent", background = "diagnostic.success" },
	{ foreground = "text.on_error", background = "surface.error" },
	{ foreground = "text.on_error", background = "version_control.conflict" },
}

local integration_names = {
	"nvim_tree",
	"cmp",
	"blink_cmp",
	"telescope",
	"fzf_lua",
	"gitsigns",
	"fugitive",
	"lspsaga",
	"rainbow_delimiters",
	"bufferline",
	"lazy",
	"which_key",
	"trouble",
	"noice",
	"snacks",
}

local function path_palette()
	local result = palette.empty()
	for _, path in ipairs(palette.paths()) do
		local category, field = path:match("^([^.]+)%.(.+)$")
		result[category][field] = path
	end
	return result
end

local function integration_contrast_pairs()
	local shared_foregrounds = {}
	for _, pair in ipairs(semantic_contrast_pairs) do
		shared_foregrounds[pair.background] = true
	end
	shared_foregrounds["text.on_accent"] = true
	shared_foregrounds["text.on_error"] = true
	local inherited_surfaces = { "surface.base", "surface.dark", "surface.raised" }
	local paths = path_palette()
	local result = {}
	for _, integration in ipairs(integration_names) do
		local groups = require("neotheme.integrations." .. integration).get(paths)
		for group, definition in pairs(groups) do
			if shared_foregrounds[definition.fg] then
				if type(definition.bg) == "string" and definition.bg:find(".", 1, true) then
					table.insert(result, {
						label = integration .. "/" .. group,
						foreground = definition.fg,
						background = definition.bg,
					})
				else
					for _, background in ipairs(inherited_surfaces) do
						table.insert(result, {
							label = integration .. "/" .. group .. " inherited " .. background,
							foreground = definition.fg,
							background = background,
						})
					end
				end
			end
		end
	end
	for mode, background in pairs({
		normal = "ui.accent",
		insert = "diagnostic.success",
		visual = "diagnostic.hint",
		replace = "diagnostic.error",
		command = "diagnostic.information",
	}) do
		table.insert(result, {
			label = "lualine/" .. mode .. ".a",
			foreground = "text.on_accent",
			background = background,
		})
	end
	table.sort(result, function(left, right)
		return left.label < right.label
	end)
	return result
end

local concrete_integration_pairs = integration_contrast_pairs()
local concrete_pair_labels = {}
for _, pair in ipairs(concrete_integration_pairs) do
	concrete_pair_labels[pair.label] = true
end
for _, label in ipairs({
	"gitsigns/GitSignsChangedelete inherited surface.base",
	"nvim_tree/NvimTreeGitMergeIcon inherited surface.base",
	"snacks/SnacksPickerGitStatusUnmerged inherited surface.dark",
}) do
	h.truthy(concrete_pair_labels[label], "concrete contrast inventory includes " .. label)
end

local function palette_color(values, path)
	local category, field = path:match("^([^.]+)%.(.+)$")
	return values[category][field]
end

local function assert_contrast(foreground, background, label)
	local ratio = contrast_ratio(foreground, background)
	h.truthy(ratio >= 4.5, string.format("%s contrast is %.2f:1", label, ratio))
	return ratio
end

local function audit_neutral_contrast(surface, values, template)
	local lowest = {
		block = { ratio = math.huge, label = nil },
		concrete = { ratio = math.huge, label = nil },
	}
	local function audit(bucket, foreground, background, label)
		local ratio = assert_contrast(foreground, background, label)
		if ratio < bucket.ratio then
			bucket.ratio = ratio
			bucket.label = label
		end
	end

	for _, pair in ipairs(preview_contrast_pairs) do
		local label = string.format(
			"%s preview %s (%s on %s)",
			template,
			pair.group,
			pair.foreground,
			pair.background
		)
		local highlight = vim.api.nvim_get_hl(surface.preview_namespace, { name = pair.group })
		h.truthy(highlight.fg, label .. " has a foreground")
		h.truthy(highlight.bg, label .. " has a background")
		h.eq(h.color(palette_color(values, pair.foreground)), highlight.fg, label .. " foreground")
		h.eq(h.color(palette_color(values, pair.background)), highlight.bg, label .. " background")
		audit(lowest.block, highlight.fg, highlight.bg, label)
	end

	for _, pair in ipairs(semantic_contrast_pairs) do
		local label =
			string.format("%s semantic %s on %s", template, pair.foreground, pair.background)
		audit(
			lowest.block,
			h.color(palette_color(values, pair.foreground)),
			h.color(palette_color(values, pair.background)),
			label
		)
	end

	for _, pair in ipairs(concrete_integration_pairs) do
		local label = string.format(
			"%s concrete %s (%s on %s)",
			template,
			pair.label,
			pair.foreground,
			pair.background
		)
		audit(
			lowest.concrete,
			h.color(palette_color(values, pair.foreground)),
			h.color(palette_color(values, pair.background)),
			label
		)
	end
	return lowest
end

local function audit_neutral_terminal(theme, values, template)
	engine.switch(theme)
	h.eq(values.text.strong, vim.g.terminal_color_15, template .. " ANSI bright white")
	h.eq(values.surface.base, vim.g.terminal_color_background, template .. " terminal background")
	h.falsy(
		values.text.on_error == vim.g.terminal_color_15,
		template .. " ANSI bright white does not use text.on_error"
	)
	return assert_contrast(
		h.color(vim.g.terminal_color_15),
		h.color(vim.g.terminal_color_background),
		template .. " terminal color 15 (text.strong on surface.base)"
	)
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

for _, family in ipairs({
	"studio",
	"clone-empty",
	"custom-empty",
	"light-base",
	"delete-no",
	"delete-cancel",
	"delete-yes",
	"delete-default",
	"nonempty",
	"delete-themes",
}) do
	themes.create_family(family)
end
for index = 1, 24 do
	themes.create_family(string.format("zz-scroll-%02d", index))
end

themes.clone("gruber-dark", "studio", "configured-theme")
themes.clone("gruber-dark", "studio", "active-theme")
themes.clone("typeset-paper", "studio", "selected-source")
themes.clone("gruber-dark", "nonempty", "nonempty-theme")
for _, theme in ipairs({
	"delete-cancel-theme",
	"delete-current-theme",
	"delete-default-theme",
	"delete-no-theme",
	"delete-yes-theme",
}) do
	themes.clone("gruber-dark", "delete-themes", theme)
end

engine.setup({ theme = "configured-theme" })
engine.switch("active-theme")
local configured_snapshot = engine._configured_snapshot()
require("neotheme.commands").register()

vim.cmd("NeothemePalette")
local surface = assert(editor._state())
h.eq("configured-theme", surface.theme, "manager starts from the configured user theme")
h.truthy(has_buffer_map(surface.navigator_buffer, "a"), "navigator maps contextual add")
h.truthy(has_buffer_map(surface.navigator_buffer, "c"), "navigator maps clone")
h.truthy(has_buffer_map(surface.navigator_buffer, "C"), "navigator maps commit")
h.truthy(has_buffer_map(surface.editor_buffer, "C"), "role editor maps uppercase commit")
h.falsy(has_buffer_map(surface.editor_buffer, "c"), "role editor leaves lowercase c unclaimed")

local configured_path = record_path("studio", "configured-theme")
replace_field(surface, "base", "#101112")
local before_commit = file_bytes(configured_path)
local no_commit = answer("n", function()
	press("C")
end)
h.eq("commit? Y/n", no_commit.prompt, "commit uses the literal confirmation")
h.eq("Y", no_commit.default, "commit confirmation defaults to Y")
h.eq(before_commit, file_bytes(configured_path), "commit no preserves disk bytes")
h.truthy(editor._state().dirty, "commit no preserves dirty state")

answer("cancel", function()
	press("C")
end)
h.eq(before_commit, file_bytes(configured_path), "commit cancel preserves disk bytes")
h.truthy(editor._state().dirty, "commit cancel preserves dirty state")

provider_answer("y", function()
	press("C")
end, "commit confirmation")
h.eq("#101112", themes.get("configured-theme").surface.base, "commit y persists the palette")
h.falsy(editor._state().dirty, "confirmed commit clears dirty state")

surface = assert(editor._state())
replace_field(surface, "base", "#202122")
local default_commit = answer("default", function()
	press("C")
end)
h.eq("Y", default_commit.default, "accepting the commit default confirms")
h.eq("#202122", themes.get("configured-theme").surface.base, "default commit persists")

surface = assert(editor._state())
replace_field(surface, "base", "#303132")
press("<C-h>")
h.eq(surface.navigator_window, vim.api.nvim_get_current_win(), "valid edits can reach navigator")
local before_lowercase = file_bytes(configured_path)
press("c")
h.eq(before_lowercase, file_bytes(configured_path), "lowercase c never commits from navigator")
h.truthy(editor._state().dirty, "lowercase c preserves dirty state")
press("2")
local add_guard = capture_error(function()
	press("a")
end)
local clone_guard = capture_error(function()
	press("c")
end)
h.truthy(add_guard:find("before adding another theme", 1, true), "add retains dirty guard")
h.truthy(clone_guard:find("before cloning another theme", 1, true), "clone retains dirty guard")
h.eq(before_lowercase, file_bytes(configured_path), "guarded add and clone never commit dirty data")
h.truthy(editor._state().dirty, "guarded add and clone preserve dirty state")
press("1")
answer("Y", function()
	press("C")
end)
h.eq("#303132", themes.get("configured-theme").surface.base, "navigator C commits")

press("<C-l>")
surface = assert(editor._state())
replace_field(surface, "base", "#123")
local invalid_bytes = file_bytes(configured_path)
answer("Y", function()
	press("C")
end)
h.eq(invalid_bytes, file_bytes(configured_path), "invalid confirmed commit preserves disk")
h.truthy(editor._state().dirty, "invalid confirmed commit remains dirty")
h.eq(1, #vim.diagnostic.get(surface.editor_buffer), "invalid confirmed commit keeps diagnostic")
replace_field(surface, "base", "#303132")
vim.cmd("write")

surface = assert(editor._state())
press("<C-h>")
press("2")
h.eq("themes", editor._state().navigator_mode, "2 selects Themes")
press("1")
h.eq("families", editor._state().navigator_mode, "1 selects Families")
press("<Tab>")
h.eq("themes", editor._state().navigator_mode, "Tab cycles to Themes")
press("<S-Tab>")
h.eq("families", editor._state().navigator_mode, "Shift-Tab cycles to Families")

local frame_lines = lines(surface.navigator_frame_buffer)
h.eq("  1 Families    2 Themes  ", frame_lines[1], "navigator tabs are fixed frame chrome")
h.eq("Enter themes  C commit", frame_lines[#frame_lines - 2], "Families help is contextual")
h.eq("a add family  d delete", frame_lines[#frame_lines - 1], "Families actions are discoverable")
h.eq("v visibility  q close", frame_lines[#frame_lines], "close action is discoverable")
h.falsy(
	vim.tbl_contains(lines(surface.navigator_buffer), frame_lines[1]),
	"scrolling list excludes protected tabs"
)
h.eq(false, vim.bo[surface.navigator_frame_buffer].modifiable, "navigator frame is protected")
h.falsy(
	pcall(vim.api.nvim_buf_set_lines, surface.navigator_frame_buffer, 0, 1, false, { "broken" }),
	"normal buffer edits cannot corrupt navigator chrome"
)

vim.o.columns = 80
vim.o.lines = 24
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
surface = assert(editor._state())
move_navigator(surface, "zz-scroll-24")
local list_view = vim.api.nvim_win_call(surface.navigator_window, vim.fn.winsaveview)
h.truthy(list_view.topline > 1, "long navigator entries scroll inside the inset list")
local frame_view = vim.api.nvim_win_call(surface.navigator_frame_window, function()
	local view = vim.fn.winsaveview()
	return { topline = view.topline, first = vim.fn.line("w0"), last = vim.fn.line("w$") }
end)
frame_lines = lines(surface.navigator_frame_buffer)
h.eq(1, frame_view.topline, "minimum navigator frame keeps tabs visible")
h.eq(1, frame_view.first, "minimum navigator viewport starts at tabs")
h.eq(#frame_lines, frame_view.last, "minimum navigator viewport includes bottom actions")
h.eq("  1 Families  2 Themes", frame_lines[1], "minimum navigator uses compact tabs")
h.eq("v visibility  q close", frame_lines[frame_view.last], "minimum viewport displays fixed help")
press("2")
frame_lines = lines(surface.navigator_frame_buffer)
h.eq("Enter select  C commit", frame_lines[#frame_lines - 2], "minimum Themes help shows commit")
h.eq(
	"a add  c clone  e edit",
	frame_lines[#frame_lines - 1],
	"minimum Themes help splits add and clone"
)
h.eq("d delete  q close", frame_lines[#frame_lines], "minimum Themes help retains delete and close")
for _, help in ipairs(vim.list_slice(frame_lines, #frame_lines - 2, #frame_lines)) do
	h.truthy(
		vim.fn.strdisplaywidth(help) <= surface.layout.navigator.width,
		"minimum Themes help fits protected chrome: " .. help
	)
end
press("1")

vim.o.columns = 140
vim.o.lines = 40
vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
surface = assert(editor._state())

local create_options = provider_answer("created-family", function()
	press("a")
end, "family name")
h.eq("New Neotheme family: ", create_options.prompt, "Families a creates a family")
h.truthy(themes.family_exists("created-family"), "Families a persists a new family")

for _, attempt in ipairs({
	{ family = "delete-no", answer = "n", label = "no" },
	{ family = "delete-cancel", answer = "cancel", label = "cancel" },
}) do
	surface = assert(editor._state())
	move_navigator(surface, attempt.family)
	local before = file_bytes(family_path(attempt.family))
	local options = answer(attempt.answer, function()
		press("d")
	end)
	h.eq("delete? Y/n", options.prompt, "family delete " .. attempt.label .. " uses confirmation")
	h.eq("Y", options.default, "family deletion defaults to Y")
	h.truthy(
		themes.family_exists(attempt.family),
		"family delete " .. attempt.label .. " preserves inventory"
	)
	h.eq(before, file_bytes(family_path(attempt.family)), "family delete preserves disk bytes")
end

surface = assert(editor._state())
move_navigator(surface, "delete-yes")
answer("y", function()
	press("d")
end)
h.falsy(themes.family_exists("delete-yes"), "family delete y removes an empty user family")
h.falsy(
	vim.tbl_contains(select(1, themes.inventory()), "delete-yes"),
	"family deletion refreshes manager inventory"
)
h.truthy(editor._state().selected_family ~= "delete-yes", "family deletion selects a fallback")

surface = assert(editor._state())
move_navigator(surface, "delete-default")
answer("default", function()
	press("d")
end)
h.falsy(themes.family_exists("delete-default"), "family delete default confirms")

surface = assert(editor._state())
move_navigator(surface, "nonempty")
local nonempty_file = file_bytes(record_path("nonempty", "nonempty-theme"))
local nonempty_message = capture_error(function()
	answer("Y", function()
		press("d")
	end)
end)
h.truthy(nonempty_message:find("is not empty", 1, true), "non-empty family rejection is actionable")
h.truthy(themes.family_exists("nonempty"), "non-empty family rejection preserves inventory")
h.eq(
	nonempty_file,
	file_bytes(record_path("nonempty", "nonempty-theme")),
	"non-empty rejection preserves bytes"
)

surface = assert(editor._state())
move_navigator(surface, "arcfield")
local bundled_families = select(1, themes.inventory())
local bundled_family_message = capture_error(function()
	answer("Y", function()
		press("d")
	end)
end)
h.truthy(
	bundled_family_message:find("bundled family", 1, true),
	"bundled family deletion is rejected"
)
h.eq(
	bundled_families,
	select(1, themes.inventory()),
	"bundled family rejection does not mutate inventory"
)

surface = assert(editor._state())
press("1")
move_navigator(surface, "studio")
press("2")
surface = assert(editor._state())
move_navigator(surface, "user selected-source")
h.truthy(contains_line(surface.navigator_buffer, "user selected-source"), "user label is explicit")
local source_palette = themes.get("selected-source")
vim.o.background = "dark"
local add_options
local dark_mode = choose("Full palette", function()
	add_options = answer("neutral-dark", function()
		press("a")
	end)
end)
h.eq(
	{ "Simplified palette", "Full palette" },
	dark_mode.items,
	"Themes a offers both creation modes"
)
h.eq("New Neotheme palette mode: ", dark_mode.options.prompt, "Themes a labels mode selection")
h.eq("New Neotheme theme: ", add_options.prompt, "Themes a prompts for the new theme name")
h.eq("", add_options.default, "Themes a does not inherit a source-based default name")
local dark_record = assert(state.load().themes["neutral-dark"])
h.eq(2, dark_record.version, "full neutral add writes schema v2")
h.eq("full", dark_record.mode, "Full palette choice persists full mode")
local complete_dark, dark_error = palette.is_complete(dark_record.palette)
h.truthy(complete_dark, dark_error)
h.truthy(state.valid_theme(dark_record), "dark neutral add passes strict record validation")
h.eq("studio", dark_record.family, "dark neutral add uses the selected family")
h.eq("neutral-dark", dark_record.name, "dark neutral add uses the prompted name")
h.eq("dark", dark_record.background, "dark neutral add uses current editor background")
h.eq("#1c1c1c", dark_record.palette.surface.base, "dark neutral add uses the internal base")
h.falsy(vim.deep_equal(source_palette, dark_record.palette), "dark add does not inherit selection")
h.falsy(
	vim.deep_equal(configured_snapshot.palette, dark_record.palette),
	"dark add does not inherit configured palette"
)
h.truthy(vim.uv.fs_stat(record_path("studio", "neutral-dark")), "dark neutral add persists JSON")
h.eq(dark_record.palette, themes.get("neutral-dark"), "dark neutral add joins the registry")
local dark_surface = assert(editor._state())
h.eq("neutral-dark", dark_surface.theme, "dark neutral add opens its role editor")
h.eq("neutral-dark", dark_surface.selected_theme, "dark neutral add selects the new theme")
h.eq(true, dark_surface.editable, "dark neutral add is editable")
h.eq(
	h.color(dark_record.palette.surface.base),
	vim.api.nvim_get_hl(dark_surface.preview_namespace, { name = "Normal" }).bg,
	"dark neutral add previews its base immediately"
)
local dark_lowest_contrast =
	audit_neutral_contrast(dark_surface, dark_record.palette, "dark neutral")
h.truthy(dark_lowest_contrast.block.label, "dark neutral audit reports its lowest block pair")
h.truthy(dark_lowest_contrast.concrete.label, "dark neutral audit reports its lowest concrete pair")

surface = assert(editor._state())
press("<C-h>")
press("1")
move_navigator(surface, "studio")
press("2")
surface = assert(editor._state())
move_navigator(surface, "user selected-source")
local clone_options = answer("theme-clone", function()
	press("c")
end)
h.eq("New Neotheme theme: ", clone_options.prompt, "Themes c prompts for the clone name")
h.eq("selected-source-copy", clone_options.default, "Themes c retains source-based default")
h.eq(source_palette, themes.get("theme-clone"), "Themes c clones the selected user theme")
h.eq("theme-clone", editor._state().theme, "theme clone transitions to its editor")

surface = assert(editor._state())
press("<C-h>")
press("1")
move_navigator(surface, "clone-empty")
press("2")
h.truthy(
	contains_line(surface.navigator_buffer, "(empty family)"),
	"empty family has no selected source"
)
answer("empty-clone", function()
	press("c")
end)
h.eq(
	configured_snapshot.palette,
	themes.get("empty-clone"),
	"empty family cloning uses the effective configured palette"
)
h.eq(
	configured_snapshot.background,
	themes.background("empty-clone"),
	"empty family cloning uses the configured background"
)
h.eq("full", state.load().themes["empty-clone"].mode, "configured snapshot clone is full")

surface = assert(editor._state())
press("<C-h>")
press("1")
move_navigator(surface, "studio")
press("2")
move_navigator(surface, "user selected-source")
press("e")
h.eq("selected-source", editor._state().theme, "Themes e edits a selected user theme")
h.eq(
	editor._state().editor_window,
	vim.api.nvim_get_current_win(),
	"Themes e focuses the role editor"
)

surface = assert(editor._state())
press("<C-h>")
press("1")
move_navigator(surface, "gruber")
press("2")
surface = assert(editor._state())
move_navigator(surface, "built-in gruber-dark")
h.truthy(
	contains_line(surface.navigator_buffer, "built-in gruber-dark"),
	"built-in label is explicit"
)
local prior_theme = surface.theme
local bundled_edit_message = capture_error(function()
	press("e")
end)
h.truthy(bundled_edit_message:find("press c", 1, true), "bundled edit rejection explains cloning")
h.eq(prior_theme, editor._state().theme, "bundled edit rejection preserves the model")

local function select_delete_theme(name)
	local current = assert(editor._state())
	press("1")
	move_navigator(current, "delete-themes")
	press("2")
	current = assert(editor._state())
	move_navigator(current, "user " .. name)
	return current
end

for _, attempt in ipairs({
	{ theme = "delete-no-theme", answer = "n", label = "no" },
	{ theme = "delete-cancel-theme", answer = "cancel", label = "cancel" },
}) do
	select_delete_theme(attempt.theme)
	local path = record_path("delete-themes", attempt.theme)
	local before = file_bytes(path)
	local options = answer(attempt.answer, function()
		press("d")
	end)
	h.eq("delete? Y/n", options.prompt, "theme delete " .. attempt.label .. " uses confirmation")
	h.eq(before, file_bytes(path), "theme delete " .. attempt.label .. " preserves disk bytes")
	h.truthy(
		themes.is_user(attempt.theme),
		"theme delete " .. attempt.label .. " preserves inventory"
	)
end

select_delete_theme("delete-yes-theme")
answer("y", function()
	press("d")
end)
h.falsy(themes.is_user("delete-yes-theme"), "theme delete y removes the selected user theme")
h.truthy(editor._state().selected_theme ~= "delete-yes-theme", "theme delete selects a fallback")

select_delete_theme("delete-current-theme")
press("e")
h.eq("delete-current-theme", editor._state().theme, "delete-current fixture is editable")
press("<C-h>")
answer("default", function()
	press("d")
end)
surface = assert(editor._state())
h.falsy(themes.is_user("delete-current-theme"), "theme delete default confirms")
h.truthy(surface.theme ~= "delete-current-theme", "deleting the edited theme loads a fallback")
h.eq(surface.selected_theme, surface.theme, "post-delete model and selection remain coherent")

local function reject_theme_deletion(family, theme, expected)
	local current = assert(editor._state())
	press("1")
	move_navigator(current, family)
	press("2")
	current = assert(editor._state())
	move_navigator(current, theme)
	local path = themes.is_user(theme) and record_path(family, theme) or nil
	local before = path and file_bytes(path) or nil
	local message = capture_error(function()
		answer("Y", function()
			press("d")
		end)
	end)
	h.truthy(message:find(expected, 1, true), expected .. " deletion is rejected")
	if path then
		h.eq(before, file_bytes(path), expected .. " rejection preserves disk bytes")
	end
end

reject_theme_deletion("studio", "user configured-theme", "configured theme")
reject_theme_deletion("studio", "user active-theme", "active theme")
reject_theme_deletion("gruber", "built-in gruber-dark", "bundled theme")

surface = assert(editor._state())
press("1")
move_navigator(surface, "light-base")
press("2")
vim.o.background = "light"
choose("Full palette", function()
	answer("neutral-light", function()
		press("a")
	end)
end)
local light_record = assert(state.load().themes["neutral-light"])
h.eq(2, light_record.version, "light full neutral add writes schema v2")
h.eq("full", light_record.mode, "light Full palette choice persists full mode")
local complete_light, light_error = palette.is_complete(light_record.palette)
h.truthy(complete_light, light_error)
h.truthy(state.valid_theme(light_record), "light neutral add passes strict record validation")
h.eq("light-base", light_record.family, "light neutral add uses the selected family")
h.eq("neutral-light", light_record.name, "light neutral add uses the prompted name")
h.eq("light", light_record.background, "light neutral add uses current editor background")
h.eq("#f5f5f5", light_record.palette.surface.base, "light neutral add uses the internal base")
h.falsy(vim.deep_equal(dark_record.palette, light_record.palette), "light and dark bases differ")
h.falsy(
	vim.deep_equal(source_palette, light_record.palette),
	"light add does not inherit selection"
)
h.falsy(
	vim.deep_equal(configured_snapshot.palette, light_record.palette),
	"light add does not inherit configured palette"
)
h.truthy(
	vim.uv.fs_stat(record_path("light-base", "neutral-light")),
	"light neutral add persists JSON"
)
local light_surface = assert(editor._state())
h.eq("neutral-light", light_surface.theme, "light neutral add opens its role editor")
h.eq(true, light_surface.editable, "light neutral add is editable")
h.eq(
	h.color(light_record.palette.surface.base),
	vim.api.nvim_get_hl(light_surface.preview_namespace, { name = "Normal" }).bg,
	"light neutral add previews its base immediately"
)
local light_lowest_contrast =
	audit_neutral_contrast(light_surface, light_record.palette, "light neutral")
h.truthy(light_lowest_contrast.block.label, "light neutral audit reports its lowest block pair")
h.truthy(
	light_lowest_contrast.concrete.label,
	"light neutral audit reports its lowest concrete pair"
)
local dark_terminal_ratio =
	audit_neutral_terminal("neutral-dark", dark_record.palette, "dark neutral")
local light_terminal_ratio =
	audit_neutral_terminal("neutral-light", light_record.palette, "light neutral")
h.truthy(dark_terminal_ratio >= 4.5, "dark neutral terminal contrast is readable")
h.truthy(light_terminal_ratio >= 4.5, "light neutral terminal contrast is readable")
vim.o.background = "dark"

local custom_palette = themes.get("typeset-paper")
custom_palette.surface.base = "#010203"
custom_palette.ui.accent = "#a1b2c3"
engine.setup({
	theme = "custom",
	configure_palette = function(target)
		for category, values in pairs(custom_palette) do
			for field, color in pairs(values) do
				target[category][field] = color
			end
		end
	end,
})
local custom_snapshot = engine._configured_snapshot()
h.eq(custom_palette, custom_snapshot.palette, "custom setup exposes its complete effective palette")
h.eq("dark", custom_snapshot.background, "custom setup exposes its effective background")
surface = assert(editor._state())
press("<C-h>")
press("1")
move_navigator(surface, "custom-empty")
press("2")
h.truthy(contains_line(surface.navigator_buffer, "(empty family)"), "custom clone target is empty")
answer("custom-snapshot", function()
	press("c")
end)
h.eq(custom_palette, themes.get("custom-snapshot"), "configured custom palette clones exactly")
h.eq("dark", themes.background("custom-snapshot"), "configured custom background clones exactly")
local persisted_custom = assert(state.load().themes["custom-snapshot"])
h.eq("full", persisted_custom.mode, "configured custom clone persists as full")
h.eq(
	custom_palette,
	persisted_custom.palette,
	"configured custom clone persists the complete palette"
)
h.eq("dark", persisted_custom.background, "configured custom clone persists background metadata")
h.truthy(
	vim.uv.fs_stat(record_path("custom-empty", "custom-snapshot")),
	"configured custom clone creates its JSON record"
)

surface = assert(editor._state())
press("<C-h>")
press("1")
move_navigator(surface, "delete-cancel")
local delayed_callback
local delayed_modal
local original_input = vim.ui.input
vim.ui.input = function(options, callback)
	h.eq("delete? Y/n", options.prompt, "stale deletion starts with the literal prompt")
	delayed_modal = open_provider_input(options, "stale delete confirmation")
	delayed_callback = callback
end
press("d")
vim.ui.input = original_input
local stale_surface = vim.deepcopy(assert(editor._state()))
vim.api.nvim_set_current_win(stale_surface.navigator_window)
vim.cmd("q!")
h.eq(nil, editor._state(), "closing during a prompt closes the workspace")
assert_closed(stale_surface, "stale prompt workspace")
h.truthy(
	vim.api.nvim_win_is_valid(delayed_modal.window),
	"workspace cleanup leaves provider-owned input cleanup to the provider"
)
close_provider_input(delayed_modal)
delayed_callback("Y")
h.truthy(themes.family_exists("delete-cancel"), "stale delete callback cannot mutate state")

vim.cmd("NeothemePalette")
surface = assert(editor._state())
local replaced_surface = vim.deepcopy(surface)
editor.edit("selected-source")
surface = assert(editor._state())
assert_closed(replaced_surface, "workspace replacement")
press("<C-h>")
press("1")
local delayed_create
original_input = vim.ui.input
vim.ui.input = function(_, callback)
	delayed_create = callback
end
press("a")
vim.ui.input = original_input
local final_surface = vim.deepcopy(surface)
vim.cmd("q!")
delayed_create("stale-family")
h.falsy(themes.family_exists("stale-family"), "stale create callback cannot mutate state")
assert_closed(final_surface, "final workspace")
