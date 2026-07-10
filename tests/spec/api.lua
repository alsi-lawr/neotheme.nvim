local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local default_theme = require("neotheme.themes").get("gruber-muted")
local engine = require("neotheme")
local palette_module = require("neotheme.palette")
local themes = require("neotheme.themes")

h.eq({ "custom", "gruber-darker", "gruber-muted" }, engine.themes(), "available themes")
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
		h.eq("", vim.fn.globpath(NEOTHEME_TEST_ROOT, "colors/" .. name .. ".*"), "theme-specific colorscheme entrypoint")
	end
end
engine.setup()

local palette = engine.palette()
palette.surface.base = palette.diagnostic.error
palette.syntax.injected = palette.diagnostic.success
h.eq(default_theme, engine.palette(), "palette mutation must not leak")

local names = engine.themes()
table.insert(names, "injected")
h.eq({ "custom", "gruber-darker", "gruber-muted" }, engine.themes(), "theme-list mutation must not leak")

h.eq(nil, engine.roles, "semantic palette replaces the separate roles API")
