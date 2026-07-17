local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local config = require("neotheme.config")

local defaults = config.get()
h.eq("gruber-dark-muted", defaults.theme, "default theme")
h.eq("interpolate", defaults.motion.level, "default motion level")
h.eq(500, defaults.motion.duration_ms, "default motion duration")
h.eq(nil, defaults.configure_palette, "default palette configurator")
h.eq(true, defaults.bold, "default bold")
h.eq(true, defaults.italic.comments, "default comment italics")
h.eq(false, defaults.italic.operators, "default operator italics")

for name, enabled in pairs(defaults.integrations) do
	h.eq(false, enabled, "integration should default off: " .. name)
end

local configure_palette = function() end
config.setup({
	theme = "custom",
	motion = { duration_ms = 750 },
	configure_palette = configure_palette,
	bold = false,
	italic = { strings = false },
	integrations = { telescope = true },
})

local partial = config.get()
h.eq("custom", partial.theme, "partial theme")
h.eq("interpolate", partial.motion.level, "default motion level is retained")
h.eq(750, partial.motion.duration_ms, "configured motion duration")
h.eq(configure_palette, partial.configure_palette, "partial palette configurator")
h.eq(false, partial.bold, "partial bold")
h.eq(false, partial.italic.strings, "partial string italics")
h.eq(true, partial.italic.comments, "deep-merged comment italics")
h.eq(true, partial.integrations.telescope, "deep-merged integration")
h.eq(false, partial.integrations.cmp, "unconfigured integration")

local invalid = {
	{ value = { unknown = true }, path = "options.unknown" },
	{ value = { motion = "fade" }, path = "options.motion" },
	{ value = { motion = { level = "fade" } }, path = "options.motion.level" },
	{ value = { motion = { duration_ms = 0 } }, path = "options.motion.duration_ms" },
	{ value = { motion = { duration_ms = 1.5 } }, path = "options.motion.duration_ms" },
	{ value = { configure_palette = true }, path = "options.configure_palette" },
	{ value = { italic = { unknown = true } }, path = "options.italic.unknown" },
	{ value = { integrations = { cmp = "yes" } }, path = "options.integrations.cmp" },
}

for _, case in ipairs(invalid) do
	local ok, err = pcall(config.setup, case.value)
	h.falsy(ok, "invalid options must fail")
	h.truthy(tostring(err):find(case.path, 1, true), "validation error must identify " .. case.path)
end

config.setup({ motion = false })
h.falsy(config.get().motion, "motion can be disabled")

local copy = config.get()
copy.italic.comments = false
h.eq(true, config.get().italic.comments, "resolved config must be mutation-safe")
