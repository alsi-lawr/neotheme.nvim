local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local engine = require("neotheme")

local function command_output()
	local original_echo = vim.api.nvim_echo
	local writes_history = false
	vim.api.nvim_echo = function(chunks, history, options)
		writes_history = history
		return original_echo(chunks, history, options)
	end
	local output = vim.api.nvim_exec2("NeothemeCurrent", { output = true }).output
	vim.api.nvim_echo = original_echo
	return output, writes_history
end

local unresolved = engine._snapshot_state()
h.eq({
	loaded = false,
	configured_theme = "gruber-dark-muted",
	session_override = false,
}, engine.current(), "default current state")
h.eq(unresolved, engine._snapshot_state(), "current is a read-only query")

engine._register_commands()
engine._register_commands()
h.eq(2, vim.fn.exists(":NeothemeCurrent"), "current command registration is idempotent")
local output, writes_history = command_output()
h.eq(
	"active: not loaded\nconfigured: gruber-dark-muted\nsession override: no",
	output,
	"unloaded current output"
)
h.eq(true, writes_history, "current output enters message history")

local configure_calls = 0
engine.setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		configure_calls = configure_calls + 1
		palette.ui.search = palette.diagnostic.error
	end,
})
h.eq({
	loaded = false,
	configured_theme = "gruber-dark",
	session_override = false,
}, engine.current(), "setup changes configuration without loading")
h.eq(1, configure_calls, "current does not resolve the palette again")

engine.load()
local loaded = {
	loaded = true,
	active_theme = "gruber-dark",
	family = "gruber",
	source = "built-in",
	configured_theme = "gruber-dark",
	background = "dark",
	session_override = false,
}
h.eq(loaded, engine.current(), "loaded current state")
output = command_output()
h.eq(
	"active: gruber-dark\nfamily: gruber\nsource: built-in\nconfigured: gruber-dark\nbackground: dark\nsession override: no",
	output,
	"loaded current output"
)

engine.switch("typeset-paper")
h.eq({
	loaded = true,
	active_theme = "typeset-paper",
	family = "typeset",
	source = "built-in",
	configured_theme = "gruber-dark",
	background = "light",
	session_override = true,
}, engine.current(), "session override current state")

vim.cmd.colorscheme("default")
h.eq({
	loaded = false,
	configured_theme = "gruber-dark",
	session_override = true,
}, engine.current(), "external colorscheme retains override intent")

engine.load()
engine.setup({ theme = "typewriter-ink" })
h.eq({
	loaded = true,
	active_theme = "gruber-dark",
	family = "gruber",
	source = "built-in",
	configured_theme = "typewriter-ink",
	background = "dark",
	session_override = false,
}, engine.current(), "setup while loaded does not change the visible theme")

local before_invalid = engine.current()
local invalid_ok, invalid_error = pcall(vim.api.nvim_exec2, "NeothemeCurrent surplus", {
	output = true,
})
h.falsy(invalid_ok, "current command rejects arguments")
h.truthy(tostring(invalid_error):find("accepts no arguments", 1, true), "current argument error")
h.eq(before_invalid, engine.current(), "invalid current command is state-atomic")
