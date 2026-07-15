local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local default_theme = require("neotheme.themes").get("gruber-dark-muted")
local engine = require("neotheme")
local palette_module = require("neotheme.palette")
local themes = require("neotheme.themes")

h.eq({
	"custom",
	"gruber-dark",
	"gruber-dark-muted",
	"gruber-darker",
	"gruber-light",
	"gruber-light-muted",
	"gruber-lighter",
	"neritic-bleached-day",
	"neritic-bleached-night",
	"neritic-day",
	"neritic-night",
}, engine.themes(), "available themes")
h.eq(default_theme, engine.palette(), "default theme palette")

for _, name in ipairs(engine.themes()) do
	if name ~= "custom" then
		local theme = themes.get(name)
		for _, path in ipairs(palette_module.paths()) do
			local category, field = path:match("^([^.]+)%.(.+)$")
			local color = theme[category][field]
			h.truthy(
				type(color) == "string" and color:match("^#%x%x%x%x%x%x$"),
				string.format("invalid %s palette entry %s", name, path)
			)
		end

		engine.setup({ theme = name })
		h.eq(theme, engine.palette(), "selectable built-in theme: " .. name)
		engine.load()
		h.eq(themes.background(name), vim.o.background, "theme background: " .. name)
		h.eq(
			"",
			vim.fn.globpath(NEOTHEME_TEST_ROOT, "colors/" .. name .. ".*"),
			"theme-specific colorscheme entrypoint"
		)
	end
end
engine.setup()

local palette = engine.palette()
palette.surface.base = palette.diagnostic.error
palette.syntax.injected = palette.diagnostic.success
h.eq(default_theme, engine.palette(), "palette mutation must not leak")

for name, background in pairs({
	["neritic-bleached-day"] = "light",
	["neritic-bleached-night"] = "dark",
	["neritic-day"] = "light",
	["neritic-night"] = "dark",
}) do
	local original = themes.get(name)
	local mutated = themes.get(name)
	mutated.surface.base = mutated.diagnostic.error
	mutated.syntax.injected = mutated.diagnostic.success
	h.eq(original, themes.get(name), name .. " palette mutation must not leak")
	h.eq(background, themes.background(name), name .. " background metadata")
end

local names = engine.themes()
table.insert(names, "injected")
h.eq({
	"custom",
	"gruber-dark",
	"gruber-dark-muted",
	"gruber-darker",
	"gruber-light",
	"gruber-light-muted",
	"gruber-lighter",
	"neritic-bleached-day",
	"neritic-bleached-night",
	"neritic-day",
	"neritic-night",
}, engine.themes(), "theme-list mutation must not leak")

h.eq(nil, engine.roles, "semantic palette replaces the separate roles API")
