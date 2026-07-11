local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local engine = require("neotheme")

engine.setup({
	configure_palette = function(palette)
		palette.ui.accent = palette.diagnostic.error
	end,
})

local palette = engine.palette()
local discovered = require("lualine.themes.neotheme")
local explicit = require("neotheme.lualine")

h.eq(explicit, discovered, "Lualine module discovery")
h.truthy(explicit == discovered, "Lualine modules should return the same cached table")

local mode_colors = {
	normal = palette.ui.accent,
	insert = palette.diagnostic.success,
	visual = palette.diagnostic.hint,
	replace = palette.diagnostic.error,
	command = palette.diagnostic.information,
}

for mode, color in pairs(mode_colors) do
	h.eq(color, explicit[mode].a.bg, mode .. " Lualine color")
	h.eq(palette.text.on_accent, explicit[mode].a.fg, mode .. " Lualine contrast")
	h.eq(palette.surface.selected, explicit[mode].b.bg, mode .. " Lualine selected surface")
	h.eq(palette.surface.base, explicit[mode].c.bg, mode .. " Lualine background")
	for _, section in ipairs({ "a", "b", "c" }) do
		h.truthy(type(explicit[mode][section]) == "table", mode .. " Lualine section " .. section)
	end
end

for _, section in ipairs({ "a", "b", "c" }) do
	h.truthy(type(explicit.inactive[section]) == "table", "inactive Lualine section " .. section)
	h.eq(
		palette.text.muted,
		explicit.inactive[section].fg,
		"inactive Lualine foreground " .. section
	)
	h.eq(
		palette.surface.base,
		explicit.inactive[section].bg,
		"inactive Lualine background " .. section
	)
end

engine.setup({ theme = "gruber-light" })
engine.load()

local refreshed_palette = engine.palette()
local refreshed = require("neotheme.lualine")

h.falsy(refreshed == explicit, "Lualine theme must refresh after a colorscheme change")
h.eq(refreshed, require("lualine.themes.neotheme"), "refreshed Lualine module discovery")
h.eq(refreshed_palette.ui.accent, refreshed.normal.a.bg, "refreshed Lualine mode color")
h.eq(refreshed_palette.surface.base, refreshed.normal.c.bg, "refreshed Lualine background")
