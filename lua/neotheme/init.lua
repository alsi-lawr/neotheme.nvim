local config = require("neotheme.config")

local M = {}
local augroup_name = "Neotheme"

local state = {
	---@type NeothemePalette?
	configured_palette = nil,
	---@type NeothemePalette?
	resolved_palette = nil,
	---@type string?
	applied_theme = nil,
	---@type NeothemeOptions?
	applied_options = nil,
	---@type NeothemePalette?
	applied_palette = nil,
	loaded = false,
	---@type string?
	override_theme = nil,
	baseline_applied = false,
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

---@class NeothemePreparedTheme
---@field options NeothemeOptions
---@field palette NeothemePalette
---@field background "dark"|"light"

---@param options NeothemeOptions
---@return NeothemePreparedTheme
local function prepare_theme(options)
	local prepared_options = copy(options)
	local palette = require("neotheme.palette")
	local themes = require("neotheme.themes")
	local background = themes.background(prepared_options.theme)
	local base = prepared_options.theme == "custom" and palette.empty()
		or themes.get(prepared_options.theme)

	return {
		options = prepared_options,
		palette = palette.resolve(base, prepared_options),
		background = background,
	}
end

---@param options NeothemeOptions
---@param palette NeothemePalette
---@return NeothemePreparedTheme
local function prepare_resolved_theme(options, palette)
	local prepared_options = copy(options)
	return {
		options = prepared_options,
		palette = copy(palette),
		background = require("neotheme.themes").background(prepared_options.theme),
	}
end

---@return NeothemePalette
local function ensure_resolved_palette()
	if state.resolved_palette == nil then
		local prepared = prepare_theme(config.get())
		state.configured_palette = copy(prepared.palette)
		state.resolved_palette = copy(prepared.palette)
	end
	return state.resolved_palette
end

local function configure_sidebars(event)
	local winhighlight = table.concat({
		"Normal:NeothemeSidebar",
		"NormalNC:NeothemeSidebar",
		"SignColumn:NeothemeSidebarSign",
		"FoldColumn:NeothemeSidebarSign",
	}, ",")

	for _, window in ipairs(vim.fn.win_findbuf(event.buf)) do
		vim.api.nvim_set_option_value("winhighlight", winhighlight, { win = window })
	end
end

function M._cleanup()
	pcall(vim.api.nvim_del_augroup_by_name, augroup_name)
	state.applied_theme = nil
	state.applied_options = nil
	state.applied_palette = nil
	state.loaded = false
	state.baseline_applied = false
end

local function create_autocmds()
	local group = vim.api.nvim_create_augroup(augroup_name, { clear = true })

	vim.api.nvim_create_autocmd("ColorSchemePre", {
		group = group,
		pattern = "*",
		callback = M._cleanup,
		desc = "Remove neotheme theme autocmds before changing colorschemes",
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = { "help", "qf" },
		callback = configure_sidebars,
		desc = "Use neotheme sidebar surfaces for help and quickfix windows",
	})
end

local function invalidate_lualine_theme()
	package.loaded["neotheme.lualine"] = nil
	package.loaded["lualine.themes.neotheme"] = nil
end

---@param prepared NeothemePreparedTheme
local function apply_prepared(prepared)
	if vim.fn.has("nvim-0.12") ~= 1 then
		error("neotheme requires Neovim 0.12 or newer")
	end

	vim.o.background = prepared.background
	if vim.g.colors_name then
		vim.cmd("highlight clear")
	end
	vim.o.termguicolors = true
	vim.g.colors_name = "neotheme"

	require("neotheme.highlights").apply(prepared.options, prepared.palette)
	invalidate_lualine_theme()
	create_autocmds()
end

---@param prepared NeothemePreparedTheme
---@param override_theme string?
---@param resolved_palette? NeothemePalette
---@param baseline_applied boolean
local function commit_applied(prepared, override_theme, resolved_palette, baseline_applied)
	state.resolved_palette = copy(resolved_palette or prepared.palette)
	state.applied_theme = prepared.options.theme
	state.applied_options = copy(prepared.options)
	state.applied_palette = copy(prepared.palette)
	state.loaded = true
	state.override_theme = override_theme
	state.baseline_applied = baseline_applied
end

---@param options? NeothemeOptions
---@return table
function M.setup(options)
	local prepared_options = config._prepare(options)
	local prepared = prepare_theme(prepared_options)

	config._commit(prepared_options)
	state.configured_palette = copy(prepared.palette)
	state.resolved_palette = copy(prepared.palette)
	state.override_theme = nil
	state.baseline_applied = false
	return M
end

---@return NeothemePalette
function M.palette()
	local palette = ensure_resolved_palette()
	return copy(palette)
end

---@param theme string
---@return table
function M.switch(theme)
	if type(theme) ~= "string" or theme == "" then
		error("neotheme: switch theme must be a non-empty string", 2)
	end
	if theme == "custom" then
		error("neotheme: cannot switch directly to the custom theme", 2)
	end

	local configured = config.get()
	local options = copy(configured)
	options.theme = theme
	local prepared = prepare_theme(options)
	local override_theme = nil
	if configured.theme ~= theme then
		override_theme = theme
	end

	apply_prepared(prepared)
	if override_theme == nil then
		state.configured_palette = copy(prepared.palette)
	end
	commit_applied(prepared, override_theme, nil, override_theme == nil)
	return M
end

---@param theme string
---@return NeothemePreparedTheme
function M._prepare_preview(theme)
	if type(theme) ~= "string" or theme == "" then
		error("neotheme: preview theme must be a non-empty string", 2)
	end
	if theme == "custom" then
		error("neotheme: cannot preview the custom theme", 2)
	end

	local options = copy(config.get())
	options.theme = theme
	return copy(prepare_theme(options))
end

---@return string configured_theme
function M.reset()
	local configured = config.get()
	if
		state.loaded
		and state.override_theme == nil
		and state.applied_theme == configured.theme
		and state.baseline_applied
	then
		return configured.theme
	end

	local prepared = prepare_theme(configured)
	apply_prepared(prepared)
	state.configured_palette = copy(prepared.palette)
	commit_applied(prepared, nil, nil, true)
	return configured.theme
end

---@return string reloaded_theme
function M.reload()
	local configured = config.get()
	local override_theme = state.override_theme
	local target = override_theme or configured.theme
	local options = copy(configured)
	options.theme = target
	local prepared = prepare_theme(options)

	apply_prepared(prepared)
	if override_theme == nil then
		state.configured_palette = copy(prepared.palette)
	end
	commit_applied(prepared, override_theme, nil, override_theme == nil)
	return target
end

---@param family? string
---@return string[]
function M.themes(family)
	return require("neotheme.themes").names(family)
end

---@return string[]
function M.families()
	return require("neotheme.themes").families()
end

---@class NeothemeCurrentState
---@field loaded boolean
---@field active_theme string?
---@field family string?
---@field configured_theme string
---@field background "dark"|"light"?
---@field session_override boolean

---@return NeothemeCurrentState
function M.current()
	local loaded = state.loaded
	local active_theme = loaded and state.applied_theme or nil
	local family = active_theme and require("neotheme.themes").family(active_theme) or nil

	return {
		loaded = loaded,
		active_theme = active_theme,
		family = family,
		configured_theme = config.get().theme,
		background = loaded and vim.o.background or nil,
		session_override = state.override_theme ~= nil,
	}
end

function M._register_commands()
	require("neotheme.commands").register()
end

---@return table
function M._state()
	return {
		configured_theme = config.get().theme,
		active_theme = state.loaded and state.applied_theme or nil,
		loaded = state.loaded,
		override_theme = state.override_theme,
	}
end

---@return table
function M._snapshot_state()
	return copy({
		loaded = state.loaded,
		configured_palette = state.configured_palette,
		applied_theme = state.applied_theme,
		applied_options = state.applied_options,
		applied_palette = state.applied_palette,
		resolved_palette = state.resolved_palette,
		override_theme = state.override_theme,
		baseline_applied = state.baseline_applied,
	})
end

---@param snapshot table
function M._restore_state(snapshot)
	if type(snapshot) ~= "table" or snapshot.loaded ~= true then
		error("neotheme: cannot restore an unloaded theme state", 2)
	end
	if
		type(snapshot.applied_theme) ~= "string"
		or type(snapshot.applied_options) ~= "table"
		or type(snapshot.applied_palette) ~= "table"
		or type(snapshot.resolved_palette) ~= "table"
	then
		error("neotheme: invalid theme state snapshot", 2)
	end
	if snapshot.applied_options.theme ~= snapshot.applied_theme then
		error("neotheme: invalid applied theme state snapshot", 2)
	end
	if snapshot.override_theme ~= nil and type(snapshot.override_theme) ~= "string" then
		error("neotheme: invalid override theme state snapshot", 2)
	end
	if snapshot.configured_palette ~= nil and type(snapshot.configured_palette) ~= "table" then
		error("neotheme: invalid configured palette state snapshot", 2)
	end
	if type(snapshot.baseline_applied) ~= "boolean" then
		error("neotheme: invalid baseline state snapshot", 2)
	end
	if
		snapshot.baseline_applied
		and (snapshot.override_theme ~= nil or snapshot.applied_theme ~= config.get().theme)
	then
		error("neotheme: inconsistent baseline state snapshot", 2)
	end

	local prepared = prepare_resolved_theme(snapshot.applied_options, snapshot.applied_palette)
	apply_prepared(prepared)
	state.configured_palette = copy(snapshot.configured_palette)
	commit_applied(
		prepared,
		snapshot.override_theme,
		snapshot.resolved_palette,
		snapshot.baseline_applied
	)
end

function M.load()
	local options = config.get()
	local prepared = state.configured_palette == nil and prepare_theme(options)
		or prepare_resolved_theme(options, state.configured_palette)

	apply_prepared(prepared)
	state.configured_palette = copy(prepared.palette)
	commit_applied(prepared, nil, nil, true)
end

return M
