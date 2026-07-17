local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))

vim.opt.runtimepath:prepend(root)
vim.opt.shortmess:append("I")

vim.o.cmdheight = 1
vim.o.cursorline = true
vim.o.laststatus = 3
vim.o.number = true
vim.o.relativenumber = false
vim.o.ruler = false
vim.o.showmode = false
vim.o.swapfile = false
vim.o.termguicolors = true

local lines = {
	"-- neotheme.nvim · preview-only theme browser",
	"",
	"local workflow = {",
	'\tfamily = "typeset",',
	'\tpreview = { "typeset-ink", "typeset-paper" },',
	'\ttransaction = "preview → confirm → keep browsing",',
	"}",
	"",
	"local function describe(flow)",
	'\treturn string.format("%s · %s", flow.family, flow.transaction)',
	"end",
	"",
	"print(describe(workflow))",
}

vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
vim.bo.filetype = "lua"
vim.bo.modified = false
vim.api.nvim_win_set_cursor(0, { 4, 1 })

local neotheme = require("neotheme")

neotheme.setup({
	theme = "gruber-dark-muted",
	motion = { level = "interpolate", duration_ms = 500 },
})
neotheme._register_commands()
vim.cmd.colorscheme("neotheme")

function _G.NeothemeDemoStatusline()
	local current = neotheme.current()
	local state = current.session_override and "session override" or "configured"
	return string.format("  Neotheme  ·  %s  ·  %s  ", current.active_theme, state)
end

vim.o.statusline = "%!v:lua.NeothemeDemoStatusline()"
