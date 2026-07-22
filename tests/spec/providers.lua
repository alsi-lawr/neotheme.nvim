local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local engine = require("neotheme")

local function provider(name, family, theme)
	return {
		version = 1,
		provider = name,
		packs = {
			[family] = {
				family = family,
				themes = {
					[theme] = {
						background = "dark",
						mode = "full",
						palette = require("neotheme.themes.gruber.dark"),
					},
				},
			},
		},
	}
end

package.preload["test_provider"] = function()
	return provider("test-provider", "external", "external-dark")
end

engine.setup({
	theme = "external-dark",
	palette_packs = { { provider = "test_provider", include = { "external" } } },
})
h.eq("external-dark", require("neotheme.config").get().theme, "provider theme config")
h.eq("dark", require("neotheme.themes").background("external-dark"), "provider background")

local returned = require("neotheme.themes").get("external-dark")
returned.surface.base = "#000000"
h.falsy(
	require("neotheme.themes").get("external-dark").surface.base == "#000000",
	"provider palettes are copied"
)

local before = require("neotheme.config").get()
local ok = pcall(engine.setup, { theme = "missing", palette_packs = {} })
h.falsy(ok, "missing replacement theme fails")
h.eq(before, require("neotheme.config").get(), "failed setup retains config")
h.eq(
	"dark",
	require("neotheme.themes").background("external-dark"),
	"failed setup retains providers"
)

package.preload["collision_provider"] = function()
	return provider("collision-provider", "collision", "gruber-dark")
end
ok = pcall(engine.setup, {
	palette_packs = { { provider = "collision_provider", include = "*" } },
})
h.falsy(ok, "built-in collision fails")
h.eq(before, require("neotheme.config").get(), "collision retains config")

package.loaded.test_provider = nil
package.loaded.collision_provider = nil
