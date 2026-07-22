local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local config = require("neotheme.config")
local engine = require("neotheme")

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
		gitsigns = h.highlight("GitSignsAdd"),
		terminal_background = vim.g.terminal_color_background,
	}
end

h.eq("gruber-dark-muted", engine.reload(), "reload returns the default target")
h.eq({
	loaded = true,
	active_theme = "gruber-dark-muted",
	family = "gruber",
	source = "built-in",
	configured_theme = "gruber-dark-muted",
	background = "dark",
	session_override = false,
}, engine.current(), "reload loads an unloaded default")
h.truthy(autocmd_count() > 0, "reload creates lifecycle autocmds")

vim.cmd.colorscheme("default")
local configure_calls = 0
local accent = "#e06b63"
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		configure_calls = configure_calls + 1
		palette.ui.accent = accent
		palette.ui.search = accent
	end,
	bold = false,
	integrations = { telescope = true },
})
h.eq(1, configure_calls, "setup resolves once")
accent = "#93c476"
h.eq("gruber-dark", engine.reload(), "reload returns the configured target")
h.eq(2, configure_calls, "reload re-resolves configuration")
h.eq(accent, engine.palette().ui.accent, "reload exposes the refreshed palette")
h.eq(h.color(accent), h.highlight("Title").fg, "reload applies refreshed highlights")
h.eq(h.color(accent), h.highlight("TelescopeMatching").fg, "reload applies integrations")
h.falsy(h.highlight("NeothemeKeyword").bold, "reload applies typography")

engine.switch("typeset-paper")
accent = "#6aa9e9"
h.eq("typeset-paper", engine.reload(), "reload retains an active override")
h.eq(true, engine.current().session_override, "reload preserves override semantics")
h.eq("typeset-paper", engine.current().active_theme, "reload targets the override")
h.eq("light", vim.o.background, "override reload keeps target background")
h.eq(accent, engine.palette().ui.accent, "override reload refreshes its palette")

local old_normal = h.highlight("Normal")
engine.setup({
	theme = "typeset-ink",
	integrations = { gitsigns = true },
})
h.eq(old_normal, h.highlight("Normal"), "setup while loaded stays unapplied")
h.eq("typeset-ink", engine.reload(), "reload applies replacement configuration")
h.eq("typeset-ink", engine.current().active_theme, "replacement reload target")
h.eq(false, engine.current().session_override, "replacement reload clears old override")
h.truthy(h.group_exists("GitSignsAdd"), "replacement integrations are applied")
h.eq({}, h.highlight("TelescopeMatching"), "removed integrations are cleared")

local failure_enabled = false
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		if failure_enabled then
			error("intentional reload failure")
		end
		palette.ui.search = palette.diagnostic.error
	end,
	integrations = { telescope = true },
})
engine.load()
engine.switch("typeset-paper")
local before_failure = visible_contract()
local cached_lualine = require("neotheme.lualine")
failure_enabled = true
local reload_ok, reload_error = pcall(engine.reload)
h.falsy(reload_ok, "reload failure is surfaced")
h.truthy(tostring(reload_error):find("intentional reload failure", 1, true), "reload failure cause")
h.eq(before_failure, visible_contract(), "failed reload is state-atomic")
h.truthy(
	package.loaded["neotheme.lualine"] == cached_lualine,
	"failed reload preserves Lualine cache"
)
failure_enabled = false

engine._register_commands()
engine._register_commands()
h.eq(2, vim.fn.exists(":NeothemeReload"), "reload command registration is idempotent")
local command_output = vim.api.nvim_exec2("NeothemeReload", { output = true }).output
h.eq("", command_output, "successful reload command is silent")
h.eq("typeset-paper", engine.current().active_theme, "reload command delegates to the API")

local before_invalid = visible_contract()
local invalid_ok, invalid_error = pcall(vim.api.nvim_exec2, "NeothemeReload surplus", {
	output = true,
})
h.falsy(invalid_ok, "reload command rejects arguments")
h.truthy(tostring(invalid_error):find("accepts no arguments", 1, true), "reload argument error")
h.eq(before_invalid, visible_contract(), "invalid reload command is state-atomic")
