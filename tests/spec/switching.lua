local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local config = require("neotheme.config")
local engine = require("neotheme")
local themes = require("neotheme.themes")

local function autocmd_count()
	local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = "Neotheme" })
	return ok and #autocmds or 0
end

local function visible_contract()
	return {
		current = engine.current(),
		config = config.get(),
		palette = engine.palette(),
		background = vim.o.background,
		colors_name = vim.g.colors_name,
		normal = h.highlight("Normal"),
		telescope = h.highlight("TelescopeMatching"),
		terminal_background = vim.g.terminal_color_background,
		terminal_foreground = vim.g.terminal_color_foreground,
	}
end

local configure_calls = 0
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		configure_calls = configure_calls + 1
		palette.ui.search = palette.diagnostic.error
	end,
	bold = false,
	integrations = { telescope = true },
})
h.eq(1, configure_calls, "setup resolves the configured palette once")

local configured_lualine = require("neotheme.lualine")
engine.switch("gruber-light")
h.eq({
	loaded = true,
	active_theme = "gruber-light",
	family = "gruber",
	configured_theme = "gruber-dark",
	background = "light",
	session_override = true,
}, engine.current(), "switch before load establishes a session override")
h.eq(2, configure_calls, "switch resolves its target once")
h.eq(h.color(engine.palette().surface.base), h.highlight("Normal").bg, "switch applies core colors")
h.eq(
	engine.palette().surface.base,
	vim.g.terminal_color_background,
	"switch applies terminal colors"
)
h.eq(
	h.color(engine.palette().ui.search),
	h.highlight("TelescopeMatching").fg,
	"switch keeps configured integrations"
)
h.falsy(h.highlight("NeothemeKeyword").bold, "switch keeps typography options")
local light_lualine = require("neotheme.lualine")
h.falsy(light_lualine == configured_lualine, "switch invalidates Lualine discovery")

local stable_autocmd_count = autocmd_count()
h.truthy(stable_autocmd_count > 0, "switch creates lifecycle autocmds")
local original_cmd = vim.cmd
local highlight_clear_calls = 0
local colorscheme_pre_calls = 0
local regression_group = vim.api.nvim_create_augroup("NeothemeSwitchAtomicity", { clear = true })
vim.api.nvim_create_autocmd("ColorSchemePre", {
	group = regression_group,
	callback = function()
		colorscheme_pre_calls = colorscheme_pre_calls + 1
	end,
})
vim.cmd = function(command)
	if command == "highlight clear" then
		highlight_clear_calls = highlight_clear_calls + 1
	end
	return original_cmd(command)
end
engine.switch("gruber-dark")
vim.cmd = original_cmd
vim.api.nvim_del_augroup_by_id(regression_group)
h.eq(0, highlight_clear_calls, "same-integration switch avoids destructive clear")
h.eq(0, colorscheme_pre_calls, "switch does not recursively reload the colorscheme")
h.eq({
	loaded = true,
	active_theme = "gruber-dark",
	family = "gruber",
	configured_theme = "gruber-dark",
	background = "dark",
	session_override = false,
}, engine.current(), "switching to the configured theme clears the override")
h.eq(stable_autocmd_count, autocmd_count(), "switch replaces rather than duplicates autocmds")

local before_invalid = visible_contract()
for _, case in ipairs({
	{ value = "missing-theme", message = "missing-theme" },
	{ value = "custom", message = "custom" },
	{ value = nil, message = "non-empty string" },
}) do
	local ok, switch_error = pcall(engine.switch, case.value)
	h.falsy(ok, "invalid switch fails: " .. tostring(case.value))
	h.truthy(tostring(switch_error):find(case.message, 1, true), "invalid switch error")
end
h.eq(before_invalid, visible_contract(), "invalid switches preserve visible state")

engine._register_commands()
engine._register_commands()
h.eq(2, vim.fn.exists(":NeothemeSwitch"), "switch command registration is idempotent")
local gruber_completion = {}
for _, theme in ipairs(engine.themes()) do
	if vim.startswith(theme, "gruber-") then
		table.insert(gruber_completion, theme)
	end
end
h.eq(
	gruber_completion,
	vim.fn.getcompletion("NeothemeSwitch gruber-", "cmdline"),
	"switch completion filters built-ins"
)

vim.cmd("NeothemeSwitch typeset-paper")
h.eq("typeset-paper", engine.current().active_theme, "switch command delegates to the API")
h.eq(true, engine.current().session_override, "switch command remains session-only")
local before_invalid_command = visible_contract()
local command_ok, command_error = pcall(vim.api.nvim_exec2, "NeothemeSwitch typeset-paper extra", {
	output = true,
})
h.falsy(command_ok, "switch command rejects surplus arguments")
h.truthy(
	tostring(command_error):find("exactly one theme argument", 1, true),
	"switch command argument error"
)
h.eq(before_invalid_command, visible_contract(), "invalid switch command is state-atomic")

vim.cmd.colorscheme("default")
h.eq(false, engine.current().loaded, "external colorscheme unloads Neotheme")
h.eq(true, engine.current().session_override, "external colorscheme retains override intent")
h.eq(0, autocmd_count(), "external colorscheme removes Neotheme autocmds")
engine.load()
h.eq("gruber-dark", engine.current().active_theme, "load restores the configured baseline")
h.eq(false, engine.current().session_override, "load clears the session override")
h.eq(
	themes.get("gruber-dark").surface.base,
	engine.palette().surface.base,
	"load restores baseline palette"
)
