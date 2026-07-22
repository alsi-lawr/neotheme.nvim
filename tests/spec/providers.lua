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
h.eq("pack:test-provider", require("neotheme.themes").source("external-dark"), "provider source")
h.truthy(vim.tbl_contains(require("neotheme").families(), "external"), "provider family is public")
h.eq({ "external-dark" }, require("neotheme").themes("external"), "provider theme is public")

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

local themes = require("neotheme.themes")
themes.set_family_enabled("external", false)
h.falsy(vim.tbl_contains(engine.families(), "external"), "hidden provider family is omitted")
h.eq("dark", themes.background("external-dark"), "hidden provider theme has exact lookup")

engine.setup({
	theme = "external-dark",
	palette_packs = { { provider = "test_provider", include = "*" } },
})
h.falsy(
	vim.tbl_contains(engine.families(), "external"),
	"provider visibility survives reconfiguration"
)
themes.create_family("copies")
local clone = themes.clone("external-dark", "copies", "external-copy")
h.eq("full", clone.mode, "provider clone becomes editable full state")
h.truthy(themes.is_user("external-copy"), "provider clone is user-owned")
h.falsy(pcall(themes.delete_theme, "external-dark"), "provider cannot be deleted in place")

engine.load()
h.eq("pack:test-provider", engine.current().source, "current state reports provider source")

local state_file =
	vim.fs.joinpath(require("neotheme.state").root(), "palettes", "copies", "external-copy.json")
local before_bytes = table.concat(vim.fn.readfile(state_file), "\n")
engine.setup({ theme = "gruber-dark", palette_packs = {} })
h.falsy(themes.is_provider("external-dark"), "provider removal clears in-memory themes")
h.eq(
	before_bytes,
	table.concat(vim.fn.readfile(state_file), "\n"),
	"provider removal preserves user bytes"
)

package.loaded.test_provider = nil
package.loaded.collision_provider = nil
