local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local built_in = require("neotheme.themes").get("gruber-dark-muted")
local engine = require("neotheme")

local notifications = {}
vim.notify = function(message, level)
	table.insert(notifications, { message = message, level = level })
end

engine.setup({
	configure_palette = function(palette)
		palette.syntax.string = palette.diagnostic.error
	end,
})
h.eq(built_in.diagnostic.error, engine.palette().syntax.string, "base-theme palette mutation")
h.eq(
	built_in.syntax.string,
	require("neotheme.themes").get("gruber-dark-muted").syntax.string,
	"base theme isolation"
)
engine.load()
h.eq(
	h.color(built_in.diagnostic.error),
	h.highlight("String").fg,
	"configured palette reaches core highlights"
)
h.eq(0, #notifications, "complete base theme should not warn")

local ok = pcall(engine.setup, { theme = "missing" })
h.falsy(ok, "unknown theme must fail")

ok = pcall(engine.setup, {
	configure_palette = function(palette)
		palette.unknown = {}
	end,
})
h.falsy(ok, "unknown palette category must fail")

ok = pcall(engine.setup, {
	configure_palette = function(palette)
		palette.syntax.unknown = palette.syntax.string
	end,
})
h.falsy(ok, "unknown palette entry must fail")

ok = pcall(engine.setup, {
	configure_palette = function(palette)
		palette.syntax.string = "not-a-color"
	end,
})
h.falsy(ok, "invalid palette color must fail")

ok = pcall(engine.setup, {
	configure_palette = function()
		return {}
	end,
})
h.falsy(ok, "palette configurator return value must fail")

notifications = {}
engine.setup({
	theme = "custom",
	configure_palette = function(palette)
		for _, category in ipairs({
			"surface",
			"text",
			"syntax",
			"diagnostic",
			"markup",
			"version_control",
			"ui",
		}) do
			h.eq({}, palette[category], "custom theme starts blank: " .. category)
		end
		palette.surface.base = built_in.surface.base
		palette.text.primary = built_in.text.primary
	end,
})
h.eq(built_in.surface.base, engine.palette().surface.base, "partial custom surface")
h.eq(built_in.text.primary, engine.palette().text.primary, "partial custom text")
h.eq(1, #notifications, "partial custom theme emits one warning")
h.eq(vim.log.levels.WARN, notifications[1].level, "missing-palette warning level")
h.truthy(
	notifications[1].message:find("diagnostic.error", 1, true),
	"warning identifies missing semantic paths"
)
h.falsy(
	notifications[1].message:find("surface.base", 1, true),
	"warning excludes configured semantic paths"
)
engine.load()
h.eq(h.color(built_in.surface.base), h.highlight("Normal").bg, "partial custom theme still loads")

notifications = {}
engine.setup({
	theme = "custom",
	configure_palette = function(palette)
		for category, values in pairs(built_in) do
			for field, color in pairs(values) do
				palette[category][field] = color
			end
		end
	end,
})
h.eq(built_in, engine.palette(), "complete custom theme")
h.eq(0, #notifications, "complete custom theme should not warn")
