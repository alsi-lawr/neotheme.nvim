local pack_root = os.getenv("NEOTHEME_PACK_ROOT")
if pack_root == nil or pack_root == "" then
	return
end

local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
vim.opt.runtimepath:prepend(pack_root)
package.loaded.neotheme_packs = nil

local expected = {
	["catppuccin-latte"] = { family = "catppuccin", background = "light" },
	["catppuccin-frappe"] = { family = "catppuccin", background = "dark" },
	["catppuccin-macchiato"] = { family = "catppuccin", background = "dark" },
	["catppuccin-mocha"] = { family = "catppuccin", background = "dark" },
	["kanagawa-wave"] = { family = "kanagawa", background = "dark" },
	["kanagawa-dragon"] = { family = "kanagawa", background = "dark" },
	["kanagawa-lotus"] = { family = "kanagawa", background = "light" },
	["rose-pine"] = { family = "rose-pine", background = "dark" },
	["rose-pine-moon"] = { family = "rose-pine", background = "dark" },
	["rose-pine-dawn"] = { family = "rose-pine", background = "light" },
	["solarized-dark"] = { family = "solarized", background = "dark" },
	["solarized-light"] = { family = "solarized", background = "light" },
	["tokyonight-night"] = { family = "tokyonight", background = "dark" },
	["tokyonight-storm"] = { family = "tokyonight", background = "dark" },
	["tokyonight-moon"] = { family = "tokyonight", background = "dark" },
	["tokyonight-day"] = { family = "tokyonight", background = "light" },
}

local engine = require("neotheme")
local themes = require("neotheme.themes")
engine.setup({
	theme = "kanagawa-wave",
	palette_packs = { { provider = "neotheme_packs", include = "*" } },
})
h.eq(16, vim.tbl_count(expected), "real provider fixture has all requested variants")
engine.load()

for name, record in pairs(expected) do
	h.eq(record.family, themes.family(name), name .. " family")
	h.eq(record.background, themes.background(name), name .. " background")
	h.eq("pack:neotheme-packs", themes.source(name), name .. " source")
	local preview = engine._prepare_preview(name)
	h.eq(record.background, preview.background, name .. " preview background")
	engine.switch(name)
	h.eq(name, engine.current().active_theme, name .. " switches")
	h.eq("pack:neotheme-packs", engine.current().source, name .. " current source")
end

engine.setup({
	theme = "solarized-dark",
	palette_packs = { { provider = "neotheme_packs", include = { "solarized" } } },
})
h.truthy(vim.tbl_contains(engine.families(), "solarized"), "explicit include retains Solarized")
for _, family in ipairs({ "catppuccin", "kanagawa", "rose-pine", "tokyonight" }) do
	h.falsy(vim.tbl_contains(engine.families(), family), "explicit include omits " .. family)
end
for _, family in ipairs({ "everforest", "nord", "gruvbox", "monokai" }) do
	h.falsy(
		vim.tbl_contains(engine.families(), family),
		"excluded family remains absent: " .. family
	)
end
