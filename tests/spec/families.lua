local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local neotheme = require("neotheme")

local expected = {
	arcfield = {
		"arcfield-graphite",
		"arcfield-porcelain",
		"arcfield-surge",
	},
	bathyal = {
		"bathyal-bioluminescence",
		"bathyal-marine-snow",
		"bathyal-midwater",
	},
	ferric = {
		"ferric-forge",
		"ferric-patina",
	},
	grove = {
		"grove-campfire",
		"grove-parchment",
	},
	gruber = {
		"gruber-dark",
		"gruber-dark-muted",
		"gruber-darker",
		"gruber-light",
		"gruber-light-muted",
		"gruber-lighter",
	},
	neritic = {
		"neritic-bleached-day",
		"neritic-bleached-night",
		"neritic-day",
		"neritic-night",
	},
	typeset = {
		"typeset-ink",
		"typeset-paper",
	},
	typewriter = {
		"typewriter-carbon",
		"typewriter-ink",
		"typewriter-low",
		"typewriter-ribbon",
		"typewriter-smudge",
	},
	understory = {
		"understory-canopy",
		"understory-clearing",
		"understory-dusk",
		"understory-mist",
	},
}
local families = {
	"arcfield",
	"bathyal",
	"ferric",
	"grove",
	"gruber",
	"neritic",
	"typeset",
	"typewriter",
	"understory",
}

h.eq(families, neotheme.families(), "canonical families")

local built_ins = {}
for _, family in ipairs(families) do
	local themes = neotheme.themes(family)
	h.eq(expected[family], themes, family .. " family themes")
	for _, theme in ipairs(themes) do
		h.falsy(built_ins[theme], "theme must appear in only one family: " .. theme)
		built_ins[theme] = true
	end
end

local expected_built_in_count = #neotheme.themes() - 1
local actual_built_in_count = vim.tbl_count(built_ins)
h.eq(31, expected_built_in_count, "built-in theme count")
h.eq(expected_built_in_count, actual_built_in_count, "complete family registry")
h.falsy(built_ins.custom, "custom must not belong to a family")

local family_copy = neotheme.families()
table.insert(family_copy, "injected")
h.eq(families, neotheme.families(), "family-list mutation must not leak")

local theme_copy = neotheme.themes("arcfield")
table.insert(theme_copy, "injected")
h.eq(expected.arcfield, neotheme.themes("arcfield"), "filtered theme mutation must not leak")

local ok, err = pcall(neotheme.themes, "unknown-family")
h.falsy(ok, "unknown family must fail")
h.truthy(
	tostring(err):find("unknown-family", 1, true),
	"unknown family error must include the supplied name"
)

h.eq(0, vim.fn.exists(":NeothemeList"), "command must not exist under --noplugin")
dofile(NEOTHEME_TEST_ROOT .. "/plugin/neotheme.lua")
h.eq(2, vim.fn.exists(":NeothemeList"), "plugin load must register the command")

vim.api.nvim_del_user_command("NeothemeList")
neotheme._register_commands()
neotheme._register_commands()
h.eq(2, vim.fn.exists(":NeothemeList"), "test hook must register idempotently")

h.eq(families, vim.fn.getcompletion("NeothemeList ", "cmdline"), "family completion")
h.eq({ "gruber" }, vim.fn.getcompletion("NeothemeList gru", "cmdline"), "prefix completion")

local grouped_lines = {}
for _, family in ipairs(families) do
	table.insert(grouped_lines, family)
	for _, theme in ipairs(expected[family]) do
		table.insert(grouped_lines, "  " .. theme)
	end
end

local grouped = vim.api.nvim_exec2("NeothemeList", { output = true }).output
h.eq(table.concat(grouped_lines, "\n"), grouped, "grouped command output")

local original_echo = vim.api.nvim_echo
local writes_message_history = false
vim.api.nvim_echo = function(chunks, history, options)
	writes_message_history = history
	return original_echo(chunks, history, options)
end
local filtered = vim.api.nvim_exec2("NeothemeList gruber", { output = true }).output
vim.api.nvim_echo = original_echo
h.eq(table.concat(expected.gruber, "\n"), filtered, "filtered command output")
h.eq(true, writes_message_history, "command output must be added to message history")

local error_echo_count = 0
vim.api.nvim_echo = function(chunks, history, options)
	error_echo_count = error_echo_count + 1
	return original_echo(chunks, history, options)
end
local invalid_ok, invalid_err = pcall(vim.api.nvim_exec2, "NeothemeList unknown-family", {
	output = true,
})
h.falsy(invalid_ok, "invalid command family must fail")
h.truthy(
	tostring(invalid_err):find("unknown-family", 1, true),
	"invalid command family error must include the supplied name"
)

local surplus_ok, surplus_err = pcall(vim.api.nvim_exec2, "NeothemeList arcfield extra", {
	output = true,
})
h.falsy(surplus_ok, "surplus command arguments must fail")
h.truthy(
	tostring(surplus_err):find("at most one family argument", 1, true),
	"surplus command error must identify the argument problem"
)
vim.api.nvim_echo = original_echo
h.eq(0, error_echo_count, "invalid commands must not print a partial inventory")
