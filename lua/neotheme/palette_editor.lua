local M = {}

local active = nil
local input_generation = 0
local navigator_namespace = vim.api.nvim_create_namespace("NeothemePaletteNavigator")
local navigator_chrome_namespace = vim.api.nvim_create_namespace("NeothemePaletteNavigatorChrome")
local editor_namespace = vim.api.nvim_create_namespace("NeothemePaletteEditor")
local editor_chrome_namespace = vim.api.nvim_create_namespace("NeothemePaletteEditorChrome")
local diagnostic_namespace = vim.api.nvim_create_namespace("NeothemePaletteDiagnostics")
local preview_namespace = vim.api.nvim_create_namespace("NeothemePalettePreview")

local full_categories = {
	{ key = "surface", label = "Surface" },
	{ key = "text", label = "Text" },
	{ key = "syntax", label = "Syntax" },
	{ key = "diagnostic", label = "Diagnostic" },
	{ key = "markup", label = "Markup" },
	{ key = "version_control", label = "Version control" },
	{ key = "ui", label = "UI" },
}

local full_fields_by_category = {}
for _, category in ipairs(full_categories) do
	full_fields_by_category[category.key] = {}
end
for _, path in ipairs(require("neotheme.palette").paths()) do
	local category, field = path:match("^([^.]+)%.(.+)$")
	table.insert(full_fields_by_category[category], field)
end
for _, category in ipairs(full_categories) do
	table.sort(full_fields_by_category[category.key])
	category.fields = full_fields_by_category[category.key]
end

local category_sets = {
	full = full_categories,
	simplified = require("neotheme.themes.simplified").categories(),
}

local rounded_border = "rounded"
local workspace_layers = {
	frame = 40,
	content = 41,
}

local workspace_winhighlight = table.concat({
	"Normal:NeothemeBrowserFloat",
	"NormalFloat:NeothemeBrowserFloat",
	"FloatBorder:NeothemeBrowserBorder",
	"FloatTitle:NeothemeBrowserTitle",
	"EndOfBuffer:NeothemeBrowserFloat",
}, ",")

local preview_lines = {
	"-- Neotheme live palette preview",
	"local palette = {",
	'  name = "neotheme",',
	"  levels = { 8, 16, 32 },",
	"}",
	"local function describe(theme, enabled)",
	"  if enabled and #theme.levels > 1 then",
	'    return string.format("%s:%d", theme.name, theme.levels[2])',
	"  end",
	'  return "disabled"',
	"end",
	"print(describe(palette, true))",
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

local function valid_window(window)
	return window ~= nil and vim.api.nvim_win_is_valid(window)
end

local function valid_buffer(buffer)
	return buffer ~= nil and vim.api.nvim_buf_is_valid(buffer)
end

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function title_chunks(text)
	return { { text, "NeothemeBrowserTitle" } }
end

local function set_window_title(window, text)
	if not valid_window(window) then
		return
	end
	local config = vim.api.nvim_win_get_config(window)
	config.title = title_chunks(text)
	config.title_pos = "center"
	vim.api.nvim_win_set_config(window, config)
end

local function apply_chrome(namespace)
	local ui = require("neotheme.ui")
	ui.apply_browser_chrome(namespace)
	vim.api.nvim_set_hl(namespace, "NeothemePaletteHelp", ui.highlight(namespace, "Comment"))
end

local function contrast(color)
	local red, green, blue = color:match("^#(%x%x)(%x%x)(%x%x)$")
	if not red then
		return "#ffffff"
	end
	local function channel(value)
		value = tonumber(value, 16) / 255
		return value <= 0.03928 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4
	end
	local luminance = 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
	return luminance > 0.179 and "#000000" or "#ffffff"
end

---@param columns integer
---@param usable_rows integer
---@param longest_name integer
---@return table? layout
---@return string? error_message
function M._layout(columns, usable_rows, longest_name)
	if columns < 80 or usable_rows < 23 then
		return nil,
			"neotheme: the palette workspace requires at least 80 columns and 23 usable rows"
	end

	local total_width = math.min(136, columns - 2)
	local navigator_width
	local editor_width
	local gap
	if total_width < 100 then
		navigator_width = 24
		editor_width = 30
		gap = 3
	else
		navigator_width = clamp(longest_name + 5, 24, 30)
		editor_width = 36
		gap = 3
	end
	local preview_width = total_width - navigator_width - editor_width - gap * 2
	if preview_width < 18 then
		return nil, "neotheme: the editor is too narrow for the palette workspace"
	end

	local height = math.min(26, usable_rows - 3)
	local row = math.floor((usable_rows - height - 2) / 2)
	local col = math.floor((columns - total_width) / 2)
	return {
		navigator = { row = row, col = col, width = navigator_width, height = height },
		editor = {
			row = row,
			col = col + navigator_width + gap,
			width = editor_width,
			height = height,
		},
		preview = {
			row = row,
			col = col + navigator_width + editor_width + gap * 2,
			width = preview_width,
			height = height,
		},
	}
end

local function current_category(surface)
	return category_sets[surface.record.mode][surface.category_index]
end

local function current_categories(surface)
	return category_sets[surface.record.mode]
end

local function selected_family(surface)
	return surface.families[surface.selected_family_index]
end

local function selected_theme(surface)
	local family = selected_family(surface)
	local themes = family and surface.themes_by_family[family] or nil
	return themes and themes[surface.selected_theme_index] or nil
end

local function surface_dirty(surface)
	return valid_buffer(surface.editor_buffer) and vim.bo[surface.editor_buffer].modified
end

local function clear_active()
	if active ~= nil and active.augroup then
		pcall(vim.api.nvim_del_augroup_by_id, active.augroup)
	end
	active = nil
end

local function prepare_close(surface)
	if active ~= surface then
		return false
	end
	surface.closing = true
	input_generation = input_generation + 1
	clear_active()
	return true
end

local function destroy(surface)
	if valid_buffer(surface.editor_buffer) then
		pcall(vim.diagnostic.reset, diagnostic_namespace, surface.editor_buffer)
	end
	for _, field in ipairs({
		"navigator_window",
		"navigator_frame_window",
		"editor_window",
		"editor_frame_window",
		"preview_window",
	}) do
		local window = surface[field]
		if valid_window(window) then
			pcall(vim.api.nvim_win_close, window, true)
		end
	end
	for _, field in ipairs({
		"navigator_buffer",
		"navigator_frame_buffer",
		"editor_buffer",
		"editor_frame_buffer",
		"preview_buffer",
	}) do
		local buffer = surface[field]
		if valid_buffer(buffer) then
			pcall(vim.api.nvim_buf_delete, buffer, { force = true })
		end
	end
	if valid_window(surface.origin_window) then
		pcall(vim.api.nvim_set_current_win, surface.origin_window)
	end
end

local function close(surface)
	if not prepare_close(surface) then
		return
	end
	destroy(surface)
end

local function defer_close(surface)
	if not prepare_close(surface) then
		return
	end
	vim.schedule(function()
		destroy(surface)
	end)
end

local function report(message)
	vim.notify(message, vim.log.levels.ERROR)
end

local function guarded_close(surface)
	if active ~= surface or surface.closing then
		return false
	end
	if surface_dirty(surface) then
		report("neotheme: modified palette; use C or :write to save, or :q! to discard and close")
		if valid_window(surface.editor_window) then
			vim.api.nvim_set_current_win(surface.editor_window)
		end
		return false
	end
	defer_close(surface)
	return true
end

local function request_input(surface, prompt, default, callback)
	input_generation = input_generation + 1
	local generation = input_generation
	local expected_active = active
	vim.ui.input({ prompt = prompt, default = default }, function(value)
		if generation ~= input_generation then
			return
		end
		if surface ~= nil then
			if active ~= surface or surface.closing then
				return
			end
		elseif active ~= expected_active then
			return
		end
		callback(value)
	end)
end

local function request_select(surface, prompt, items, callback)
	input_generation = input_generation + 1
	local generation = input_generation
	local expected_active = active
	vim.ui.select(items, { prompt = prompt }, function(choice)
		if generation ~= input_generation then
			return
		end
		if surface ~= nil then
			if active ~= surface or surface.closing then
				return
			end
		elseif active ~= expected_active then
			return
		end
		callback(choice)
	end)
end

local function input(surface, prompt, default, callback)
	request_input(surface, prompt, default, function(value)
		if value and value ~= "" then
			callback(value)
		end
	end)
end

local function confirm(surface, prompt, callback)
	request_input(surface, prompt, "Y", function(value)
		if value == "Y" or value == "y" then
			callback()
		end
	end)
end

local function theme_record(theme)
	local themes = require("neotheme.themes")
	if themes.is_user(theme) then
		return copy(assert(require("neotheme.state").load().themes[theme])), true
	end
	return {
		version = 2,
		family = themes.family(theme),
		name = theme,
		background = themes.background(theme),
		mode = "full",
		palette = themes.get(theme),
	},
		false
end

local function apply_preview(surface, record, label)
	local options = require("neotheme.config").get()
	options.theme = record.name
	options.configure_palette = nil
	local expanded = require("neotheme.themes").expand(record)
	require("neotheme.highlights").apply_preview(options, expanded, preview_namespace)
	apply_chrome(preview_namespace)
	vim.api.nvim_win_set_hl_ns(surface.preview_window, preview_namespace)
	surface.preview_background = record.background
	set_window_title(
		surface.preview_window,
		" Preview - " .. (label or record.name) .. " - " .. record.background .. " "
	)
end

local function mark_editor_tokens(surface)
	vim.api.nvim_buf_clear_namespace(surface.editor_buffer, editor_namespace, 0, -1)
	local count = 0
	for line_number, line in ipairs(vim.api.nvim_buf_get_lines(surface.editor_buffer, 0, -1, false)) do
		local first, last, color = line:find("(#[%x][%x][%x][%x][%x][%x])")
		if first then
			local group = "NeothemePaletteToken" .. color:sub(2)
			vim.api.nvim_set_hl(editor_namespace, group, { fg = contrast(color), bg = color })
			vim.api.nvim_buf_set_extmark(
				surface.editor_buffer,
				editor_namespace,
				line_number - 1,
				first - 1,
				{ end_col = last, hl_group = group }
			)
			count = count + 1
		end
	end
	surface.token_count = count
end

local function category_tab_lines(surface)
	if surface.record.mode == "simplified" then
		return {
			"  1 Surface  2 Text",
			"  3 Syntax  4 Signals",
		}
	end
	if surface.layout.editor.width < 32 then
		return {
			"  1 Surface  2 Text",
			"  3 Syntax",
			"  4 Diagnostic  5 Markup",
			"  6 Version control  7 UI",
		}
	end
	return {
		"  1 Surface  2 Text  3 Syntax",
		"  4 Diagnostic  5 Markup",
		"  6 Version control  7 UI",
	}
end

local function editor_content_layout(layout, mode)
	local tab_count = mode == "simplified" and 2 or (layout.editor.width < 32 and 4 or 3)
	return {
		row = layout.editor.row + tab_count + 1,
		col = layout.editor.col + 1,
		width = layout.editor.width,
		height = layout.editor.height - tab_count - 1,
	}
end

local function apply_editor_content_layout(surface)
	if not valid_window(surface.editor_window) then
		return
	end
	local layout = editor_content_layout(surface.layout, surface.record.mode)
	local config = vim.api.nvim_win_get_config(surface.editor_window)
	config.row = layout.row
	config.col = layout.col
	config.width = layout.width
	config.height = layout.height
	vim.api.nvim_win_set_config(surface.editor_window, config)
end

local function render_category_chrome(surface)
	local lines = {}
	for _, line in ipairs(category_tab_lines(surface)) do
		table.insert(lines, line)
	end
	while #lines < surface.layout.editor.height - 1 do
		table.insert(lines, "")
	end
	local help = "C-h nav | C commit | q close"
	table.insert(lines, help)

	vim.api.nvim_set_option_value("modifiable", true, { buf = surface.editor_frame_buffer })
	vim.api.nvim_buf_set_lines(surface.editor_frame_buffer, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = surface.editor_frame_buffer })
	vim.api.nvim_buf_clear_namespace(surface.editor_frame_buffer, editor_chrome_namespace, 0, -1)
	for line_index, line in ipairs(category_tab_lines(surface)) do
		for index, category in ipairs(current_categories(surface)) do
			local text = tostring(index) .. " " .. category.label
			local start = line:find(text, 1, true)
			if start then
				vim.api.nvim_buf_set_extmark(
					surface.editor_frame_buffer,
					editor_chrome_namespace,
					line_index - 1,
					start - 1,
					{
						end_col = start - 1 + #text,
						hl_group = index == surface.category_index and "NeothemeBrowserTabActive"
							or "NeothemeBrowserTabInactive",
					}
				)
			end
		end
	end
	vim.api.nvim_buf_set_extmark(
		surface.editor_frame_buffer,
		editor_chrome_namespace,
		#lines - 1,
		0,
		{ end_col = #help, hl_group = "NeothemePaletteHelp" }
	)
end

local function render_category(surface, preserve_dirty)
	local category = current_category(surface)
	local fields = category.fields
	local lines = { "background = " .. surface.record.background }
	surface.metadata_line = 0
	surface.field_lines = {}
	for _, field in ipairs(fields) do
		local color = surface.record.mode == "simplified" and surface.record.palette[field]
			or surface.record.palette[category.key][field]
		table.insert(lines, field .. " = " .. color)
		surface.field_lines[field] = #lines - 1
	end

	local dirty = preserve_dirty and surface_dirty(surface) or false
	surface.rendering = true
	vim.api.nvim_set_option_value("modifiable", true, { buf = surface.editor_buffer })
	vim.api.nvim_buf_set_lines(surface.editor_buffer, 0, -1, false, lines)
	vim.api.nvim_set_option_value("buftype", surface.editable and "acwrite" or "nofile", {
		buf = surface.editor_buffer,
	})
	vim.api.nvim_set_option_value("modifiable", surface.editable, { buf = surface.editor_buffer })
	vim.bo[surface.editor_buffer].modified = dirty
	surface.rendering = false
	vim.diagnostic.reset(diagnostic_namespace, surface.editor_buffer)
	apply_chrome(editor_namespace)
	mark_editor_tokens(surface)
	render_category_chrome(surface)
	local mode_label = surface.record.mode == "simplified" and "Simplified" or "Full"
	set_window_title(
		surface.editor_frame_window,
		" Roles - " .. mode_label .. " - " .. category.label .. " "
	)
	if valid_window(surface.editor_window) and #fields > 0 then
		pcall(
			vim.api.nvim_win_set_cursor,
			surface.editor_window,
			{ surface.field_lines[fields[1]] + 1, 0 }
		)
	end
end

local function set_field_diagnostic(surface, row, col, end_col, message)
	vim.diagnostic.set(diagnostic_namespace, surface.editor_buffer, {
		{
			lnum = row,
			col = col,
			end_col = end_col,
			severity = vim.diagnostic.severity.ERROR,
			message = message,
		},
	})
end

local function reject_field(surface, row, col, end_col, message)
	set_field_diagnostic(surface, row, col, end_col, message)
	mark_editor_tokens(surface)
	return false
end

local function value_position(line, value)
	local equals = line:find("=", 1, true)
	if value == "" then
		local insertion = #line
		return insertion, insertion
	end
	local first = equals and line:find(value, equals + 1, true) or line:find(value, 1, true)
	first = first or 1
	return first - 1, first - 1 + #value
end

local function field_position(line, field)
	local first = line:find(field, 1, true) or 1
	return first - 1, first - 1 + #field
end

local function parsed_field(line)
	return line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
end

local function source_field(surface, category, field)
	if surface.record.mode == "simplified" then
		return field
	end
	return category.key .. "." .. field
end

local function sync_category(surface)
	if not surface.editable then
		return true
	end
	local category = current_category(surface)
	local lines = vim.api.nvim_buf_get_lines(surface.editor_buffer, 0, -1, false)
	local metadata_line = lines[surface.metadata_line + 1] or ""
	local metadata_field, background = parsed_field(metadata_line)
	if metadata_field ~= "background" then
		return reject_field(
			surface,
			surface.metadata_line,
			0,
			#metadata_line,
			"neotheme: expected background metadata"
		)
	end

	local fields = category.fields
	local expected_index = {}
	for index, field in ipairs(fields) do
		expected_index[field] = index
	end
	local seen = {}
	local parsed = {}
	for index, field in ipairs(fields) do
		local row = index
		local line = lines[row + 1]
		if line == nil then
			local insertion_row = math.max(#lines - 1, 0)
			local insertion_line = lines[insertion_row + 1] or ""
			return reject_field(
				surface,
				insertion_row,
				#insertion_line,
				#insertion_line,
				"neotheme: missing field "
					.. source_field(surface, category, field)
					.. " after this row"
			)
		end

		local actual_field, value = parsed_field(line)
		if actual_field == nil then
			return reject_field(
				surface,
				row,
				0,
				#line,
				"neotheme: expected field " .. source_field(surface, category, field)
			)
		end
		local col, end_col = field_position(line, actual_field)
		if actual_field == "background" or seen[actual_field] then
			return reject_field(
				surface,
				row,
				col,
				end_col,
				"neotheme: duplicate field " .. source_field(surface, category, actual_field)
			)
		end
		if expected_index[actual_field] == nil then
			return reject_field(
				surface,
				row,
				col,
				end_col,
				"neotheme: unknown field " .. source_field(surface, category, actual_field)
			)
		end
		if actual_field ~= field then
			local expected_later = false
			for later = row + 2, #lines do
				if parsed_field(lines[later]) == field then
					expected_later = true
					break
				end
			end
			local message
			if expected_later then
				message = "neotheme: field "
					.. source_field(surface, category, field)
					.. " is out of order before "
					.. source_field(surface, category, actual_field)
			else
				message = "neotheme: missing field "
					.. source_field(surface, category, field)
					.. " before "
					.. source_field(surface, category, actual_field)
			end
			return reject_field(surface, row, col, end_col, message)
		end
		seen[actual_field] = true
		parsed[field] = { line = line, row = row, value = value }
	end

	local expected_rows = #fields + 1
	if #lines > expected_rows then
		local row = expected_rows
		local line = lines[row + 1]
		local actual_field = parsed_field(line)
		if actual_field then
			local col, end_col = field_position(line, actual_field)
			local message
			if actual_field == "background" or seen[actual_field] then
				message = "neotheme: duplicate field "
					.. source_field(surface, category, actual_field)
			else
				message = "neotheme: unknown field "
					.. source_field(surface, category, actual_field)
			end
			return reject_field(surface, row, col, end_col, message)
		end
		return reject_field(surface, row, 0, #line, "neotheme: unexpected surplus row")
	end

	if background ~= "dark" and background ~= "light" then
		local col, end_col = value_position(metadata_line, background)
		return reject_field(
			surface,
			surface.metadata_line,
			col,
			end_col,
			"neotheme: background must be dark or light"
		)
	end

	local values = surface.record.mode == "simplified" and copy(surface.record.palette)
		or copy(surface.record.palette[category.key])
	for _, field in ipairs(fields) do
		local item = parsed[field]
		if type(item.value) ~= "string" or not item.value:match("^#%x%x%x%x%x%x$") then
			local col, end_col = value_position(item.line, item.value)
			return reject_field(
				surface,
				item.row,
				col,
				end_col,
				"neotheme: palette."
					.. source_field(surface, category, field)
					.. " must be a #RRGGBB color"
			)
		end
		values[field] = item.value
	end

	surface.record.background = background
	if surface.record.mode == "simplified" then
		surface.record.palette = values
	else
		surface.record.palette[category.key] = values
	end
	surface.last_valid = copy(surface.record)
	vim.diagnostic.reset(diagnostic_namespace, surface.editor_buffer)
	mark_editor_tokens(surface)
	apply_preview(surface, surface.record)
	return true
end

local function focus_editor(surface)
	if not sync_category(surface) then
		vim.api.nvim_set_current_win(surface.editor_window)
		return false
	end
	vim.api.nvim_set_current_win(surface.editor_window)
	apply_preview(surface, surface.record)
	return true
end

local function focus_navigator(surface)
	if not sync_category(surface) then
		vim.api.nvim_set_current_win(surface.editor_window)
		return false
	end
	vim.api.nvim_set_current_win(surface.navigator_window)
	return true
end

local function switch_category(surface, index, wrap)
	local count = #current_categories(surface)
	local target = wrap and ((index - 1) % count) + 1 or index
	if target < 1 or target > count then
		return false
	end
	if target == surface.category_index then
		return true
	end
	if not sync_category(surface) then
		return false
	end
	surface.category_index = target
	render_category(surface, true)
	apply_preview(surface, surface.record)
	return true
end

local function index_of(values, target)
	for index, value in ipairs(values) do
		if value == target then
			return index
		end
	end
	return nil
end

local function refresh_inventory(surface, preferred_family, preferred_theme)
	local themes = require("neotheme.themes")
	local families, themes_by_family, diagnostics = themes.inventory()
	surface.families = families
	surface.themes_by_family = themes_by_family
	surface.diagnostics = diagnostics
	surface.selected_family_index = index_of(families, preferred_family)
		or clamp(surface.selected_family_index or 1, 1, math.max(#families, 1))
	local family = selected_family(surface)
	local members = family and themes_by_family[family] or {}
	surface.selected_theme_index = index_of(members, preferred_theme)
		or clamp(surface.selected_theme_index or 1, 1, math.max(#members, 1))
end

local function display_name(name, width)
	if vim.fn.strdisplaywidth(name) <= width then
		return name
	end
	return vim.fn.strcharpart(name, 0, math.max(width - 3, 1)) .. "..."
end

local function navigator_tab_line(surface)
	if surface.layout.navigator.width < 28 then
		return "  1 Families  2 Themes"
	end
	return "  1 Families    2 Themes  "
end

local function navigator_content_layout(layout)
	return {
		row = layout.navigator.row + 3,
		col = layout.navigator.col + 1,
		width = layout.navigator.width,
		height = layout.navigator.height - 5,
	}
end

local function navigator_help(surface)
	if surface.navigator_mode == "families" then
		return {
			"Enter themes  C commit",
			"a add family  d delete",
			"v visibility  q close",
		}
	end
	return {
		"Enter select  C commit",
		"a add  c clone  e edit",
		"d delete  q close",
	}
end

local function render_navigator_frame(surface)
	local line = navigator_tab_line(surface)
	local lines = { line, "" }
	local help = navigator_help(surface)
	while #lines < surface.layout.navigator.height - #help do
		table.insert(lines, "")
	end
	for _, help_line in ipairs(help) do
		table.insert(lines, help_line)
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = surface.navigator_frame_buffer })
	vim.api.nvim_buf_set_lines(surface.navigator_frame_buffer, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = surface.navigator_frame_buffer })
	vim.api.nvim_buf_clear_namespace(
		surface.navigator_frame_buffer,
		navigator_chrome_namespace,
		0,
		-1
	)
	for _, tab in ipairs({
		{ text = "1 Families", mode = "families" },
		{ text = "2 Themes", mode = "themes" },
	}) do
		local start = assert(line:find(tab.text, 1, true)) - 1
		vim.api.nvim_buf_set_extmark(
			surface.navigator_frame_buffer,
			navigator_chrome_namespace,
			0,
			start,
			{
				end_col = start + #tab.text,
				hl_group = surface.navigator_mode == tab.mode and "NeothemeBrowserTabActive"
					or "NeothemeBrowserTabInactive",
			}
		)
	end
	for index = #lines - #help + 1, #lines do
		vim.api.nvim_buf_set_extmark(
			surface.navigator_frame_buffer,
			navigator_chrome_namespace,
			index - 1,
			0,
			{ end_col = #lines[index], hl_group = "NeothemePaletteHelp" }
		)
	end
end

local function render_navigator(surface)
	local lines = {}
	local rows = {}
	local selected_row = 1
	local width = surface.layout.navigator.width
	if surface.navigator_mode == "families" then
		for index, family in ipairs(surface.families) do
			local selected = index == surface.selected_family_index
			local enabled = require("neotheme.themes").family_enabled(family)
			local prefix = (selected and "> " or "  ") .. (enabled and "[x] " or "[ ] ")
			local line = prefix .. display_name(family, width - vim.fn.strdisplaywidth(prefix))
			table.insert(lines, line)
			rows[#lines] = { family = family, family_index = index }
			if selected then
				selected_row = #lines
			end
		end
		set_window_title(surface.navigator_frame_window, " Neotheme - Families ")
	else
		local family = selected_family(surface)
		local members = family and surface.themes_by_family[family] or {}
		for index, theme in ipairs(members) do
			local selected = index == surface.selected_theme_index
			local kind = require("neotheme.themes").is_user(theme) and "user" or "built-in"
			local prefix = (selected and "> " or "  ") .. kind .. " "
			local line = prefix .. display_name(theme, width - vim.fn.strdisplaywidth(prefix))
			table.insert(lines, line)
			rows[#lines] = { family = family, theme = theme, theme_index = index }
			if selected then
				selected_row = #lines
			end
		end
		if #members == 0 then
			table.insert(lines, "  (empty family)")
		end
		set_window_title(
			surface.navigator_frame_window,
			" Neotheme - " .. (family or "Themes") .. " "
		)
	end

	if #surface.diagnostics > 0 then
		table.insert(lines, "")
		table.insert(lines, "! State diagnostics: " .. tostring(#surface.diagnostics))
		for _, diagnostic in ipairs(surface.diagnostics) do
			table.insert(lines, "! " .. diagnostic)
		end
	end

	surface.navigator_rows = rows
	surface.rendering_navigator = true
	vim.api.nvim_set_option_value("modifiable", true, { buf = surface.navigator_buffer })
	vim.api.nvim_buf_set_lines(surface.navigator_buffer, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = surface.navigator_buffer })
	vim.api.nvim_buf_clear_namespace(surface.navigator_buffer, navigator_namespace, 0, -1)
	render_navigator_frame(surface)
	vim.api.nvim_win_set_cursor(surface.navigator_window, { selected_row, 0 })
	surface.rendering_navigator = false
end

local function preview_selected(surface)
	local theme = selected_theme(surface)
	if theme then
		local record = theme_record(theme)
		apply_preview(surface, record, theme)
	end
end

local function handle_navigator_movement(surface)
	if surface.rendering_navigator or surface.closing then
		return
	end
	if not sync_category(surface) then
		vim.api.nvim_set_current_win(surface.editor_window)
		return
	end
	local row = vim.api.nvim_win_get_cursor(surface.navigator_window)[1]
	local entry = surface.navigator_rows[row]
	if not entry then
		render_navigator(surface)
		return
	end
	if surface.navigator_mode == "families" then
		surface.selected_family_index = entry.family_index
		local members = surface.themes_by_family[entry.family]
		surface.selected_theme_index = clamp(surface.selected_theme_index, 1, math.max(#members, 1))
		preview_selected(surface)
	else
		surface.selected_theme_index = entry.theme_index
		preview_selected(surface)
	end
	render_navigator(surface)
end

local function toggle_navigator_mode(surface)
	local mode = surface.navigator_mode == "families" and "themes" or "families"
	surface.navigator_mode = mode
	render_navigator(surface)
	preview_selected(surface)
end

local function set_navigator_mode(surface, mode)
	if surface.navigator_mode == mode then
		return
	end
	surface.navigator_mode = mode
	render_navigator(surface)
	preview_selected(surface)
end

local function load_user_theme(surface, theme)
	if surface.record.name == theme then
		vim.api.nvim_set_current_win(surface.editor_window)
		apply_preview(surface, surface.record)
		return true
	end
	if surface_dirty(surface) then
		report("neotheme: write or discard the current palette before selecting another theme")
		return false
	end
	local record, editable = theme_record(theme)
	if not editable then
		return false
	end
	surface.record = record
	surface.last_valid = copy(record)
	surface.theme = theme
	surface.family = record.family
	surface.editable = true
	surface.category_index = 1
	apply_editor_content_layout(surface)
	refresh_inventory(surface, record.family, theme)
	render_navigator(surface)
	render_category(surface, false)
	apply_preview(surface, record)
	vim.api.nvim_set_current_win(surface.editor_window)
	return true
end

local function load_theme(surface, theme, focus_roles)
	local record, editable = theme_record(theme)
	surface.record = record
	surface.last_valid = copy(record)
	surface.theme = theme
	surface.family = record.family
	surface.editable = editable
	surface.category_index = 1
	apply_editor_content_layout(surface)
	refresh_inventory(surface, record.family, theme)
	render_navigator(surface)
	render_category(surface, false)
	apply_preview(surface, record)
	vim.api.nvim_set_current_win(focus_roles and surface.editor_window or surface.navigator_window)
end

local function persist_surface(surface)
	if not surface.editable then
		return false, "neotheme: bundled themes are read-only; press c on Themes to clone one"
	end
	if not sync_category(surface) then
		return false, "neotheme: palette was not saved; fix the field diagnostic"
	end
	surface.writing = true
	local ok, saved_or_error = pcall(require("neotheme.themes").save, surface.record)
	surface.writing = false
	if not ok then
		return false, tostring(saved_or_error)
	end
	surface.record = saved_or_error
	surface.last_valid = copy(saved_or_error)
	vim.bo[surface.editor_buffer].modified = false
	vim.notify("neotheme: saved palette '" .. surface.record.name .. "'")
	return true
end

local function commit_palette(surface)
	if not surface.editable then
		report("neotheme: bundled themes are read-only; press c on Themes to clone one")
		return
	end
	confirm(surface, "commit? Y/n", function()
		local saved, save_error = persist_surface(surface)
		if not saved then
			report(save_error)
		end
	end)
end

local begin_clone

local function activate_navigator_entry(surface)
	if surface.navigator_mode == "families" then
		toggle_navigator_mode(surface)
		return
	end
	local theme = selected_theme(surface)
	if not theme then
		return
	end
	if require("neotheme.themes").is_user(theme) then
		load_user_theme(surface, theme)
	else
		report("neotheme: bundled themes are read-only; press c to clone the selected theme")
	end
end

begin_clone = function(surface, source, preferred_family)
	if surface and surface_dirty(surface) then
		report("neotheme: write or discard the current palette before cloning another theme")
		return
	end
	input(surface, "Neotheme palette family: ", preferred_family or "", function(family)
		input(surface, "Neotheme palette name: ", source .. "-copy", function(name)
			local themes = require("neotheme.themes")
			local ok, create_error = pcall(function()
				if not themes.family_exists(family) then
					themes.create_family(family)
				end
				themes.clone(source, family, name)
			end)
			if not ok then
				report(tostring(create_error))
				return
			end
			if surface and active == surface then
				load_user_theme(surface, name)
			else
				M.edit(name)
			end
		end)
	end)
end

local function create_family(surface)
	input(surface, "New Neotheme family: ", "", function(name)
		local ok, create_error = pcall(require("neotheme.themes").create_family, name)
		if not ok then
			report(tostring(create_error))
			return
		end
		refresh_inventory(surface, name, nil)
		surface.navigator_mode = "families"
		render_navigator(surface)
	end)
end

local function add_theme(surface)
	if surface_dirty(surface) then
		report("neotheme: commit or discard the current palette before adding another theme")
		return
	end
	local family = selected_family(surface)
	if not family then
		return
	end
	request_select(surface, "New Neotheme palette mode: ", {
		"Simplified palette",
		"Full palette",
	}, function(choice)
		if choice == nil then
			return
		end
		local mode = choice == "Simplified palette" and "simplified"
			or (choice == "Full palette" and "full" or nil)
		if mode == nil then
			return
		end
		if surface_dirty(surface) then
			report("neotheme: commit or discard the current palette before adding another theme")
			return
		end
		local background = vim.o.background == "light" and "light" or "dark"
		local neutral = mode == "simplified" and "neotheme.neutral_simplified_palette"
			or "neotheme.neutral_palette"
		local snapshot = {
			background = background,
			mode = mode,
			palette = require(neutral).get(background),
		}
		input(surface, "New Neotheme theme: ", "", function(name)
			local ok, create_or_error =
				pcall(require("neotheme.themes").create_snapshot, snapshot, family, name)
			if not ok then
				report(tostring(create_or_error))
				return
			end
			refresh_inventory(surface, family, name)
			surface.navigator_mode = "themes"
			load_user_theme(surface, name)
		end)
	end)
end

local function clone_theme(surface)
	if surface_dirty(surface) then
		report("neotheme: commit or discard the current palette before cloning another theme")
		return
	end
	local family = selected_family(surface)
	if not family then
		return
	end
	local source = selected_theme(surface)
	local configured = source == nil and require("neotheme")._configured_snapshot() or nil
	local default_name = source or require("neotheme.config").get().theme
	input(surface, "New Neotheme theme: ", default_name .. "-copy", function(name)
		local themes = require("neotheme.themes")
		local ok, clone_or_error
		if source ~= nil then
			ok, clone_or_error = pcall(themes.clone, source, family, name)
		else
			ok, clone_or_error = pcall(themes.create_snapshot, configured, family, name)
		end
		if not ok then
			report(tostring(clone_or_error))
			return
		end
		refresh_inventory(surface, family, name)
		surface.navigator_mode = "themes"
		load_user_theme(surface, name)
	end)
end

local function edit_selected_theme(surface)
	local theme = selected_theme(surface)
	if not theme then
		return
	end
	if not require("neotheme.themes").is_user(theme) then
		report("neotheme: bundled themes are read-only; press c to clone the selected theme")
		return
	end
	load_user_theme(surface, theme)
end

local function first_inventory_theme(surface)
	for family_index, family in ipairs(surface.families) do
		local members = surface.themes_by_family[family]
		if #members > 0 then
			surface.selected_family_index = family_index
			surface.selected_theme_index = 1
			return members[1]
		end
	end
	return nil
end

local function delete_family(surface)
	local family = selected_family(surface)
	if not family then
		return
	end
	confirm(surface, "delete? Y/n", function()
		local ok, delete_error = pcall(require("neotheme.themes").delete_family, family)
		if not ok then
			report(tostring(delete_error))
			return
		end
		refresh_inventory(surface, nil, nil)
		surface.navigator_mode = "families"
		render_navigator(surface)
		preview_selected(surface)
	end)
end

local function delete_theme(surface)
	local theme = selected_theme(surface)
	local family = selected_family(surface)
	if not theme or not family then
		return
	end
	confirm(surface, "delete? Y/n", function()
		local deleting_current = surface.record.name == theme
		local ok, delete_error = pcall(require("neotheme.themes").delete_theme, theme)
		if not ok then
			report(tostring(delete_error))
			return
		end
		refresh_inventory(surface, family, nil)
		surface.navigator_mode = "themes"
		local fallback = selected_theme(surface) or first_inventory_theme(surface)
		if deleting_current then
			if fallback == nil then
				close(surface)
				return
			end
			load_theme(surface, fallback, false)
		else
			render_navigator(surface)
			preview_selected(surface)
		end
	end)
end

local function toggle_family_visibility(surface)
	local family = selected_family(surface)
	if not family then
		return
	end
	local themes = require("neotheme.themes")
	local ok, toggle_error =
		pcall(themes.set_family_enabled, family, not themes.family_enabled(family))
	if not ok then
		report(tostring(toggle_error))
		return
	end
	refresh_inventory(surface, family, selected_theme(surface))
	render_navigator(surface)
end

local function configure_navigator(surface)
	vim.api.nvim_set_option_value("number", false, { win = surface.navigator_window })
	vim.api.nvim_set_option_value("relativenumber", false, { win = surface.navigator_window })
	vim.api.nvim_set_option_value("cursorline", true, { win = surface.navigator_window })
	vim.api.nvim_set_option_value("wrap", false, { win = surface.navigator_window })
	vim.api.nvim_set_option_value("winhighlight", workspace_winhighlight, {
		win = surface.navigator_window,
	})
	vim.api.nvim_win_set_hl_ns(surface.navigator_window, navigator_namespace)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = surface.navigator_frame_buffer })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = surface.navigator_frame_buffer })
	vim.api.nvim_set_option_value("swapfile", false, { buf = surface.navigator_frame_buffer })
	vim.api.nvim_set_option_value("modifiable", false, { buf = surface.navigator_frame_buffer })
	vim.api.nvim_set_option_value("number", false, { win = surface.navigator_frame_window })
	vim.api.nvim_set_option_value("relativenumber", false, { win = surface.navigator_frame_window })
	vim.api.nvim_set_option_value("wrap", false, { win = surface.navigator_frame_window })
	vim.api.nvim_set_option_value("winhighlight", workspace_winhighlight, {
		win = surface.navigator_frame_window,
	})
	vim.api.nvim_win_set_hl_ns(surface.navigator_frame_window, navigator_namespace)

	local options = { buffer = surface.navigator_buffer, silent = true, nowait = true }
	for _, key in ipairs({ "<Tab>", "<S-Tab>" }) do
		vim.keymap.set("n", key, function()
			toggle_navigator_mode(surface)
		end, options)
	end
	vim.keymap.set("n", "1", function()
		set_navigator_mode(surface, "families")
	end, options)
	vim.keymap.set("n", "2", function()
		set_navigator_mode(surface, "themes")
	end, options)
	vim.keymap.set("n", "<C-l>", function()
		focus_editor(surface)
	end, options)
	vim.keymap.set("n", "<CR>", function()
		activate_navigator_entry(surface)
	end, options)
	vim.keymap.set("n", "c", function()
		if surface.navigator_mode == "themes" then
			clone_theme(surface)
		end
	end, options)
	vim.keymap.set("n", "C", function()
		commit_palette(surface)
	end, options)
	vim.keymap.set("n", "a", function()
		if surface.navigator_mode == "families" then
			create_family(surface)
		else
			add_theme(surface)
		end
	end, options)
	vim.keymap.set("n", "e", function()
		if surface.navigator_mode == "themes" then
			edit_selected_theme(surface)
		end
	end, options)
	vim.keymap.set("n", "d", function()
		if surface.navigator_mode == "families" then
			delete_family(surface)
		else
			delete_theme(surface)
		end
	end, options)
	vim.keymap.set("n", "v", function()
		if surface.navigator_mode == "families" then
			toggle_family_visibility(surface)
		end
	end, options)
	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.keymap.set("n", key, function()
			guarded_close(surface)
		end, options)
	end
end

local function configure_editor(surface)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = surface.editor_buffer })
	vim.api.nvim_set_option_value("swapfile", false, { buf = surface.editor_buffer })
	vim.api.nvim_set_option_value("filetype", "", { buf = surface.editor_buffer })
	vim.api.nvim_set_option_value("number", false, { win = surface.editor_window })
	vim.api.nvim_set_option_value("relativenumber", false, { win = surface.editor_window })
	vim.api.nvim_set_option_value("signcolumn", "yes", { win = surface.editor_window })
	vim.api.nvim_set_option_value("wrap", false, { win = surface.editor_window })
	vim.api.nvim_set_option_value("scrolloff", 0, { win = surface.editor_window })
	vim.api.nvim_set_option_value("winhighlight", workspace_winhighlight, {
		win = surface.editor_window,
	})
	vim.api.nvim_win_set_hl_ns(surface.editor_window, editor_namespace)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = surface.editor_frame_buffer })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = surface.editor_frame_buffer })
	vim.api.nvim_set_option_value("swapfile", false, { buf = surface.editor_frame_buffer })
	vim.api.nvim_set_option_value("modifiable", false, { buf = surface.editor_frame_buffer })
	vim.api.nvim_set_option_value("number", false, { win = surface.editor_frame_window })
	vim.api.nvim_set_option_value("relativenumber", false, { win = surface.editor_frame_window })
	vim.api.nvim_set_option_value("wrap", false, { win = surface.editor_frame_window })
	vim.api.nvim_set_option_value("winhighlight", workspace_winhighlight, {
		win = surface.editor_frame_window,
	})
	vim.api.nvim_win_set_hl_ns(surface.editor_frame_window, editor_namespace)

	local options = { buffer = surface.editor_buffer, silent = true, nowait = true }
	vim.keymap.set("n", "<C-h>", function()
		focus_navigator(surface)
	end, options)
	vim.keymap.set("n", "C", function()
		commit_palette(surface)
	end, options)
	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.keymap.set("n", key, function()
			guarded_close(surface)
		end, options)
	end
	vim.keymap.set("n", "[", function()
		switch_category(surface, surface.category_index - 1, true)
	end, options)
	vim.keymap.set("n", "]", function()
		switch_category(surface, surface.category_index + 1, true)
	end, options)
	for index = 1, #full_categories do
		vim.keymap.set("n", tostring(index), function()
			switch_category(surface, index, false)
		end, options)
	end

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = surface.augroup,
		buffer = surface.editor_buffer,
		callback = function()
			if active == surface and not surface.rendering and not surface.writing then
				sync_category(surface)
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		group = surface.augroup,
		buffer = surface.editor_buffer,
		callback = function()
			local saved, save_error = persist_surface(surface)
			if not saved then
				vim.api.nvim_err_writeln(save_error)
				return
			end
		end,
	})
end

local function configure_preview(surface)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = surface.preview_buffer })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = surface.preview_buffer })
	vim.api.nvim_set_option_value("swapfile", false, { buf = surface.preview_buffer })
	vim.api.nvim_set_option_value("modifiable", false, { buf = surface.preview_buffer })
	vim.api.nvim_set_option_value("filetype", "lua", { buf = surface.preview_buffer })
	vim.api.nvim_set_option_value("number", false, { win = surface.preview_window })
	vim.api.nvim_set_option_value("relativenumber", false, { win = surface.preview_window })
	vim.api.nvim_set_option_value("wrap", false, { win = surface.preview_window })
	vim.api.nvim_set_option_value("winhighlight", workspace_winhighlight, {
		win = surface.preview_window,
	})
	pcall(vim.treesitter.start, surface.preview_buffer, "lua")
end

local function set_window_layout(window, layout)
	local config = vim.api.nvim_win_get_config(window)
	config.row = layout.row
	config.col = layout.col
	config.width = layout.width
	config.height = layout.height
	vim.api.nvim_win_set_config(window, config)
end

local function resize(surface)
	local valid_category = sync_category(surface)
	local layout, layout_error =
		M._layout(vim.o.columns, vim.o.lines - vim.o.cmdheight, surface.longest_name)
	if not layout then
		report(layout_error)
		return
	end
	set_window_layout(surface.navigator_frame_window, layout.navigator)
	set_window_layout(surface.navigator_window, navigator_content_layout(layout))
	set_window_layout(surface.editor_frame_window, layout.editor)
	set_window_layout(surface.editor_window, editor_content_layout(layout, surface.record.mode))
	set_window_layout(surface.preview_window, layout.preview)
	surface.layout = layout
	render_navigator(surface)
	if valid_category then
		render_category(surface, true)
		apply_preview(surface, surface.record)
	else
		render_category_chrome(surface)
	end
end

local function create_lifecycle_autocmds(surface)
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = surface.augroup,
		buffer = surface.navigator_buffer,
		callback = function()
			if active == surface then
				handle_navigator_movement(surface)
			end
		end,
	})
	vim.api.nvim_create_autocmd("VimResized", {
		group = surface.augroup,
		callback = function()
			if active == surface then
				resize(surface)
			end
		end,
	})
	vim.api.nvim_create_autocmd("QuitPre", {
		group = surface.augroup,
		callback = function()
			if
				active == surface
				and surface_dirty(surface)
				and vim.api.nvim_get_current_win() ~= surface.editor_window
			then
				error("neotheme: modified palette must be saved or discarded from the role editor")
			end
		end,
	})
	for _, window in ipairs({
		surface.navigator_window,
		surface.navigator_frame_window,
		surface.editor_window,
		surface.editor_frame_window,
		surface.preview_window,
	}) do
		vim.api.nvim_create_autocmd("WinClosed", {
			group = surface.augroup,
			pattern = tostring(window),
			callback = function()
				if active == surface and not surface.closing then
					defer_close(surface)
				end
			end,
		})
	end
end

local function longest_inventory_name()
	local families, by_family = require("neotheme.themes").inventory()
	local longest = 0
	for _, family in ipairs(families) do
		longest = math.max(longest, vim.fn.strdisplaywidth(family))
		for _, theme in ipairs(by_family[family]) do
			longest = math.max(longest, vim.fn.strdisplaywidth(theme))
		end
	end
	return longest
end

local function open_workspace(theme, focus_roles)
	if active ~= nil then
		if theme == nil then
			focus_navigator(active)
			return
		end
		if theme and active.theme == theme then
			vim.api.nvim_set_current_win(
				focus_roles and active.editor_window or active.navigator_window
			)
			return
		end
		if surface_dirty(active) then
			error(
				"neotheme: write or discard the modified palette before opening another workspace",
				2
			)
		end
	end

	local themes = require("neotheme.themes")
	local initial_theme = theme
	if initial_theme == nil then
		local configured = require("neotheme.config").get().theme
		if configured ~= "custom" then
			local exact = pcall(themes.get, configured)
			if exact then
				initial_theme = configured
			end
		end
	end
	if initial_theme == nil then
		local families, by_family = themes.inventory()
		for _, family in ipairs(families) do
			if #by_family[family] > 0 then
				initial_theme = by_family[family][1]
				break
			end
		end
	end
	if initial_theme == nil then
		error("neotheme: the palette workspace has no themes to display", 2)
	end
	local record, editable = theme_record(initial_theme)
	local longest_name = longest_inventory_name()
	local layout, layout_error =
		M._layout(vim.o.columns, vim.o.lines - vim.o.cmdheight, longest_name)
	if not layout then
		error(layout_error, 2)
	end
	if active ~= nil then
		close(active)
	end

	apply_chrome(navigator_namespace)
	apply_chrome(editor_namespace)
	local surface = {
		kind = "workspace",
		origin_window = vim.api.nvim_get_current_win(),
		navigator_buffer = vim.api.nvim_create_buf(false, true),
		navigator_frame_buffer = vim.api.nvim_create_buf(false, true),
		editor_frame_buffer = vim.api.nvim_create_buf(false, true),
		editor_buffer = vim.api.nvim_create_buf(false, true),
		preview_buffer = vim.api.nvim_create_buf(false, true),
		augroup = vim.api.nvim_create_augroup("NeothemePaletteWorkspace", { clear = true }),
		layout = layout,
		longest_name = longest_name,
		navigator_mode = "families",
		selected_family_index = 1,
		selected_theme_index = 1,
		category_index = 1,
		record = record,
		last_valid = copy(record),
		theme = initial_theme,
		family = record.family,
		editable = editable,
	}
	vim.api.nvim_buf_set_name(surface.navigator_buffer, "neotheme://palette/navigator")
	vim.api.nvim_buf_set_name(surface.navigator_frame_buffer, "neotheme://palette/navigator-frame")
	vim.api.nvim_buf_set_name(surface.editor_frame_buffer, "neotheme://palette/roles-frame")
	vim.api.nvim_buf_set_name(surface.editor_buffer, "neotheme://palette/roles")
	vim.api.nvim_buf_set_name(surface.preview_buffer, "neotheme://palette/preview")
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = surface.navigator_buffer })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = surface.navigator_buffer })
	vim.api.nvim_set_option_value("swapfile", false, { buf = surface.navigator_buffer })

	surface.navigator_frame_window = vim.api.nvim_open_win(surface.navigator_frame_buffer, false, {
		relative = "editor",
		row = layout.navigator.row,
		col = layout.navigator.col,
		width = layout.navigator.width,
		height = layout.navigator.height,
		style = "minimal",
		border = rounded_border,
		title = title_chunks(" Neotheme - Families "),
		title_pos = "center",
		focusable = false,
		zindex = workspace_layers.frame,
	})
	local navigator_layout = navigator_content_layout(layout)
	surface.navigator_window = vim.api.nvim_open_win(surface.navigator_buffer, not focus_roles, {
		relative = "editor",
		row = navigator_layout.row,
		col = navigator_layout.col,
		width = navigator_layout.width,
		height = navigator_layout.height,
		style = "minimal",
		focusable = true,
		zindex = workspace_layers.content,
	})
	surface.editor_frame_window = vim.api.nvim_open_win(surface.editor_frame_buffer, false, {
		relative = "editor",
		row = layout.editor.row,
		col = layout.editor.col,
		width = layout.editor.width,
		height = layout.editor.height,
		style = "minimal",
		border = rounded_border,
		title = title_chunks(
			" Roles - " .. (record.mode == "simplified" and "Simplified" or "Full") .. " - Surface "
		),
		title_pos = "center",
		focusable = false,
		zindex = workspace_layers.frame,
	})
	local content_layout = editor_content_layout(layout, record.mode)
	surface.editor_window = vim.api.nvim_open_win(surface.editor_buffer, focus_roles == true, {
		relative = "editor",
		row = content_layout.row,
		col = content_layout.col,
		width = content_layout.width,
		height = content_layout.height,
		style = "minimal",
		focusable = true,
		zindex = workspace_layers.content,
	})
	surface.preview_window = vim.api.nvim_open_win(surface.preview_buffer, false, {
		relative = "editor",
		row = layout.preview.row,
		col = layout.preview.col,
		width = layout.preview.width,
		height = layout.preview.height,
		style = "minimal",
		border = rounded_border,
		title = title_chunks(" Preview - " .. initial_theme .. " "),
		title_pos = "center",
		focusable = false,
		zindex = workspace_layers.frame,
	})

	vim.api.nvim_buf_set_lines(surface.preview_buffer, 0, -1, false, preview_lines)
	configure_navigator(surface)
	configure_editor(surface)
	configure_preview(surface)
	refresh_inventory(surface, record.family, initial_theme)
	active = surface
	render_navigator(surface)
	render_category(surface, false)
	apply_preview(surface, record)
	create_lifecycle_autocmds(surface)
	vim.api.nvim_set_current_win(focus_roles and surface.editor_window or surface.navigator_window)
end

function M.edit(theme)
	if not require("neotheme.themes").is_user(theme) then
		error("neotheme: bundled themes are read-only; clone one before editing", 2)
	end
	open_workspace(theme, true)
end

function M.manager()
	open_workspace(nil, false)
end

---@param argument? string
function M.open(argument)
	if argument == nil or argument == "" then
		return M.manager()
	end
	local themes = require("neotheme.themes")
	if not themes.is_builtin(argument) and not themes.is_user(argument) then
		error("neotheme: unknown theme '" .. argument .. "'", 2)
	end
	if themes.is_user(argument) then
		return M.edit(argument)
	end
	begin_clone(active, argument, themes.family(argument))
end

function M._state()
	if active == nil then
		return nil
	end
	return copy({
		kind = active.kind,
		theme = active.theme,
		family = active.family,
		mode = active.record.mode,
		editable = active.editable,
		navigator_buffer = active.navigator_buffer,
		navigator_window = active.navigator_window,
		navigator_frame_buffer = active.navigator_frame_buffer,
		navigator_frame_window = active.navigator_frame_window,
		editor_buffer = active.editor_buffer,
		editor_window = active.editor_window,
		editor_frame_buffer = active.editor_frame_buffer,
		editor_frame_window = active.editor_frame_window,
		preview_buffer = active.preview_buffer,
		preview_window = active.preview_window,
		navigator_namespace = navigator_namespace,
		navigator_chrome_namespace = navigator_chrome_namespace,
		editor_namespace = editor_namespace,
		editor_chrome_namespace = editor_chrome_namespace,
		preview_namespace = preview_namespace,
		diagnostic_namespace = diagnostic_namespace,
		navigator_mode = active.navigator_mode,
		selected_family = selected_family(active),
		selected_theme = selected_theme(active),
		category_index = active.category_index,
		category = current_category(active).key,
		field_lines = active.field_lines,
		token_count = active.token_count,
		record = active.record,
		last_valid = active.last_valid,
		metadata_line = active.metadata_line,
		layout = active.layout,
		preview_background = active.preview_background,
		diagnostics = active.diagnostics,
		dirty = surface_dirty(active),
	})
end

return M
