local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local engine = require("neotheme")
local palette_module = require("neotheme.palette")
local themes = require("neotheme.themes")

local function assert_sorted_unique(values, label)
	local sorted = vim.deepcopy(values)
	table.sort(sorted)
	h.eq(sorted, values, label .. " are sorted")
	local seen = {}
	for _, value in ipairs(values) do
		h.falsy(seen[value], label .. " contain duplicate " .. value)
		seen[value] = true
	end
end

local names = engine.themes()
h.truthy(#names > 1, "theme registry contains built-ins")
assert_sorted_unique(names, "theme names")
h.truthy(vim.tbl_contains(names, "custom"), "theme registry exposes custom configuration")
h.eq(themes.get("gruber-dark-muted"), engine.palette(), "default palette matches default theme")

for _, name in ipairs(names) do
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

		local background = themes.background(name)
		h.truthy(background == "dark" or background == "light", name .. " background metadata")
		h.truthy(type(themes.family(name)) == "string", name .. " family metadata")
		engine.setup({ theme = name })
		h.eq(theme, engine.palette(), name .. " is selectable")
		engine.load()
		h.eq(background, vim.o.background, name .. " applies its background")
		h.eq(h.color(theme.surface.base), h.highlight("Normal").bg, name .. " applies core colors")
	end
end

local original = themes.get(names[1] == "custom" and names[2] or names[1])
local mutated = themes.get(names[1] == "custom" and names[2] or names[1])
mutated.surface.base = mutated.diagnostic.error
h.eq(
	original,
	themes.get(names[1] == "custom" and names[2] or names[1]),
	"theme palettes are mutation-safe"
)

local public_palette = engine.palette()
local expected_palette = engine.palette()
public_palette.surface.base = public_palette.diagnostic.error
h.eq(expected_palette, engine.palette(), "resolved palette is mutation-safe")
