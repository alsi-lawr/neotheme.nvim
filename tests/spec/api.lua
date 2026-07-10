local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local built_in = require("neotheme.themes").get("gruber-muted")
local engine = require("neotheme")
local palette_module = require("neotheme.palette")

h.eq({ "custom", "gruber-muted" }, engine.themes(), "available themes")
h.eq(built_in, engine.palette(), "default theme palette")

for _, path in ipairs(palette_module.paths()) do
	local category, field = path:match("^([^.]+)%.(.+)$")
	local color = built_in[category][field]
	h.truthy(type(color) == "string" and color:match("^#%x%x%x%x%x%x$"), "invalid built-in palette entry " .. path)
end

local palette = engine.palette()
palette.surface.base = palette.diagnostic.error
palette.syntax.injected = palette.diagnostic.success
h.eq(built_in, engine.palette(), "palette mutation must not leak")

local names = engine.themes()
table.insert(names, "injected")
h.eq({ "custom", "gruber-muted" }, engine.themes(), "theme-list mutation must not leak")

h.eq(nil, engine.roles, "semantic palette replaces the separate roles API")
h.eq("", vim.fn.globpath(NEOTHEME_TEST_ROOT, "colors/gruber-muted.*"), "legacy colorscheme entrypoint")
