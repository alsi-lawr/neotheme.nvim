local p = require("neotheme").palette()

local function mode(color)
	return {
		a = { fg = p.text.on_accent, bg = color, gui = "bold" },
		b = { fg = p.text.strong, bg = p.surface.selected },
		c = { fg = p.text.primary, bg = p.surface.base },
	}
end

return {
	normal = mode(p.ui.accent),
	insert = mode(p.diagnostic.success),
	visual = mode(p.diagnostic.hint),
	replace = mode(p.diagnostic.error),
	command = mode(p.diagnostic.information),
	inactive = {
		a = { fg = p.text.muted, bg = p.surface.base },
		b = { fg = p.text.muted, bg = p.surface.base },
		c = { fg = p.text.muted, bg = p.surface.base },
	},
}
