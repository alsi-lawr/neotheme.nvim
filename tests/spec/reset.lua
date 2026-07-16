local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local config = require("neotheme.config")
local engine = require("neotheme")
local themes = require("neotheme.themes")

local function visible_contract()
	return {
		current = engine.current(),
		config = config.get(),
		palette = engine.palette(),
		background = vim.o.background,
		colors_name = vim.g.colors_name,
		normal = h.highlight("Normal"),
		cmp = h.highlight("CmpItemAbbrMatch"),
		terminal_background = vim.g.terminal_color_background,
	}
end

h.eq("gruber-dark-muted", engine.reset(), "reset returns the default target")
h.eq("gruber-dark-muted", engine.current().active_theme, "reset loads an unloaded default")
h.eq(false, engine.current().session_override, "default reset has no override")

vim.cmd.colorscheme("default")
local configure_calls = 0
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		configure_calls = configure_calls + 1
		palette.ui.search = palette.diagnostic.error
	end,
	bold = false,
})
h.eq(1, configure_calls, "setup resolves once")
h.eq("gruber-dark", engine.reset(), "reset applies configured baseline")
h.eq(2, configure_calls, "first reset refreshes the baseline")
h.eq("gruber-dark", engine.reset(), "reset returns target on no-op")
h.eq(2, configure_calls, "applied baseline reset is a no-op")

engine.switch("typeset-paper")
h.eq(true, engine.current().session_override, "switch establishes override before reset")
h.eq("gruber-dark", engine.reset(), "reset returns to configured baseline")
h.eq("gruber-dark", engine.current().active_theme, "reset clears override target")
h.eq(false, engine.current().session_override, "reset clears override semantics")
h.eq("dark", vim.o.background, "reset restores configured background")

local old_normal = h.highlight("Normal")
engine.setup({
	theme = "gruber-dark",
	bold = true,
	integrations = { cmp = true },
})
h.eq(old_normal, h.highlight("Normal"), "same-theme setup remains unapplied")
h.eq(false, engine._snapshot_state().baseline_applied, "same-theme setup invalidates no-op marker")
engine.reset()
h.truthy(h.highlight("NeothemeKeyword").bold, "reset applies replacement typography")
h.truthy(h.group_exists("CmpItemAbbrMatch"), "reset applies replacement integrations")
h.eq(true, engine._snapshot_state().baseline_applied, "reset restores no-op marker")

local reference = themes.get("ferric-forge")
local custom_calls = 0
local custom_failure = false
local custom_received_empty = {}
local function configure_custom(palette)
	custom_calls = custom_calls + 1
	table.insert(custom_received_empty, next(palette.surface) == nil)
	if custom_failure then
		error("intentional reset failure")
	end
	for category, values in pairs(reference) do
		for field, color in pairs(values) do
			if palette[category][field] == nil then
				palette[category][field] = color
			end
		end
	end
end

vim.cmd.colorscheme("default")
engine.setup({ theme = "custom", configure_palette = configure_custom })
h.eq("custom", engine.reset(), "reset applies custom baseline")
h.eq(
	true,
	custom_received_empty[#custom_received_empty],
	"custom reset starts from an empty palette"
)
h.eq(reference, engine.palette(), "custom reset exposes configured palette")
h.eq("custom", engine.current().active_theme, "custom reset target")

engine.switch("typeset-paper")
h.eq(
	false,
	custom_received_empty[#custom_received_empty],
	"custom-baseline switch starts from built-in colors"
)
h.eq("custom", engine.reset(), "reset returns from built-in override to custom")
h.eq(true, custom_received_empty[#custom_received_empty], "custom override reset starts empty")
h.eq(false, engine.current().session_override, "custom reset clears override")

engine.switch("typeset-paper")
local before_failure = visible_contract()
local cached_lualine = require("neotheme.lualine")
custom_failure = true
local reset_ok, reset_error = pcall(engine.reset)
h.falsy(reset_ok, "reset failure is surfaced")
h.truthy(tostring(reset_error):find("intentional reset failure", 1, true), "reset failure cause")
h.eq(before_failure, visible_contract(), "failed reset is state-atomic")
h.truthy(
	package.loaded["neotheme.lualine"] == cached_lualine,
	"failed reset preserves Lualine cache"
)
custom_failure = false

engine._register_commands()
engine._register_commands()
h.eq(2, vim.fn.exists(":NeothemeReset"), "reset command registration is idempotent")
local command_output = vim.api.nvim_exec2("NeothemeReset", { output = true }).output
h.eq("", command_output, "successful reset command is silent")
h.eq("custom", engine.current().active_theme, "reset command delegates to the API")

engine.switch("typeset-paper")
local before_invalid = visible_contract()
local invalid_ok, invalid_error = pcall(vim.api.nvim_exec2, "NeothemeReset surplus", {
	output = true,
})
h.falsy(invalid_ok, "reset command rejects arguments")
h.truthy(tostring(invalid_error):find("accepts no arguments", 1, true), "reset argument error")
h.eq(before_invalid, visible_contract(), "invalid reset command is state-atomic")
