local config = require("neotheme.config")

local M = {}
local augroup_name = "Neotheme"
---@type NeothemePalette?
local resolved_palette = nil

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

---@return NeothemePalette
local function resolve_theme()
	local options = config.get()
	local palette = require("neotheme.palette")
	local base = options.theme == "custom" and palette.empty()
		or require("neotheme.themes").get(options.theme)
	resolved_palette = palette.resolve(base, options)
	return resolved_palette
end

---@return NeothemePalette
local function ensure_theme()
	if resolved_palette == nil then
		return resolve_theme()
	end
	return resolved_palette
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

---@param options? NeothemeOptions
---@return table
function M.setup(options)
	config.setup(options)
	resolve_theme()
	return M
end

---@return NeothemePalette
function M.palette()
	local palette = ensure_theme()
	return copy(palette)
end

---@return string[]
function M.themes()
	return require("neotheme.themes").names()
end

function M.load()
	if vim.fn.has("nvim-0.12") ~= 1 then
		error("neotheme requires Neovim 0.12 or newer")
	end

	vim.o.background = require("neotheme.themes").background(config.get().theme)
	if vim.g.colors_name then
		vim.cmd("highlight clear")
	end
	vim.o.termguicolors = true
	vim.g.colors_name = "neotheme"

	local palette = ensure_theme()
	require("neotheme.highlights").apply(config.get(), palette)
	invalidate_lualine_theme()
	create_autocmds()
end

return M
