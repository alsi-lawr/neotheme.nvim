local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local default_theme = require("neotheme.themes").get("gruber-dark-muted")
local engine = require("neotheme")
local palette_module = require("neotheme.palette")
local themes = require("neotheme.themes")

h.eq({
	"arcfield-graphite",
	"arcfield-porcelain",
	"arcfield-surge",
	"bathyal-bioluminescence",
	"bathyal-marine-snow",
	"bathyal-midwater",
	"custom",
	"ferric-forge",
	"ferric-patina",
	"grove-campfire",
	"grove-parchment",
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
	"typeset-ink",
	"typeset-paper",
	"typewriter-carbon",
	"typewriter-ink",
	"typewriter-low",
	"typewriter-ribbon",
	"typewriter-smudge",
	"understory-canopy",
	"understory-clearing",
	"understory-dusk",
	"understory-mist",
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
	["arcfield-graphite"] = "dark",
	["arcfield-porcelain"] = "light",
	["arcfield-surge"] = "dark",
}) do
	local original = themes.get(name)
	local mutated = themes.get(name)
	mutated.surface.base = mutated.diagnostic.error
	mutated.syntax.injected = mutated.diagnostic.success
	h.eq(original, themes.get(name), name .. " palette mutation must not leak")
	h.eq(background, themes.background(name), name .. " background metadata")
end

for name, background in pairs({
	["bathyal-bioluminescence"] = "dark",
	["bathyal-marine-snow"] = "light",
	["bathyal-midwater"] = "dark",
}) do
	local original = themes.get(name)
	local mutated = themes.get(name)
	mutated.surface.base = mutated.diagnostic.error
	mutated.syntax.injected = mutated.diagnostic.success
	h.eq(original, themes.get(name), name .. " palette mutation must not leak")
	h.eq(background, themes.background(name), name .. " background metadata")
end

for name, background in pairs({
	["ferric-forge"] = "dark",
	["ferric-patina"] = "light",
	["grove-campfire"] = "dark",
	["grove-parchment"] = "light",
}) do
	local original = themes.get(name)
	local mutated = themes.get(name)
	mutated.surface.base = mutated.diagnostic.error
	mutated.syntax.injected = mutated.diagnostic.success
	h.eq(original, themes.get(name), name .. " palette mutation must not leak")
	h.eq(background, themes.background(name), name .. " background metadata")
end

for name, background in pairs({
	["neritic-bleached-day"] = "light",
	["neritic-bleached-night"] = "dark",
	["neritic-day"] = "light",
	["neritic-night"] = "dark",
	["typeset-ink"] = "dark",
	["typeset-paper"] = "light",
	["understory-canopy"] = "dark",
	["understory-clearing"] = "light",
	["understory-dusk"] = "dark",
	["understory-mist"] = "light",
}) do
	local original = themes.get(name)
	local mutated = themes.get(name)
	mutated.surface.base = mutated.diagnostic.error
	mutated.syntax.injected = mutated.diagnostic.success
	h.eq(original, themes.get(name), name .. " palette mutation must not leak")
	h.eq(background, themes.background(name), name .. " background metadata")
end

for name, background in pairs({
	["typewriter-carbon"] = "dark",
	["typewriter-ink"] = "light",
	["typewriter-low"] = "light",
	["typewriter-ribbon"] = "dark",
	["typewriter-smudge"] = "light",
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
	"arcfield-graphite",
	"arcfield-porcelain",
	"arcfield-surge",
	"bathyal-bioluminescence",
	"bathyal-marine-snow",
	"bathyal-midwater",
	"custom",
	"ferric-forge",
	"ferric-patina",
	"grove-campfire",
	"grove-parchment",
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
	"typeset-ink",
	"typeset-paper",
	"typewriter-carbon",
	"typewriter-ink",
	"typewriter-low",
	"typewriter-ribbon",
	"typewriter-smudge",
	"understory-canopy",
	"understory-clearing",
	"understory-dusk",
	"understory-mist",
}, engine.themes(), "theme-list mutation must not leak")

h.eq(nil, engine.roles, "semantic palette replaces the separate roles API")
