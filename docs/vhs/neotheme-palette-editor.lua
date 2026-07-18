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
	"-- neotheme.nvim - persistent palette workspace",
	"",
	"local palette_workflow = {",
	'\tfamily = "atelier",',
	'\tsources = { "simplified", "full" },',
	'\tpreview = "private until commit",',
	"}",
	"",
	"local function describe(workflow)",
	'\treturn string.format("%s: %s", workflow.family, workflow.preview)',
	"end",
	"",
	"print(describe(palette_workflow))",
}

vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
vim.bo.filetype = "lua"
vim.bo.modified = false
vim.api.nvim_win_set_cursor(0, { 4, 1 })

local themes = require("neotheme.themes")
themes.create_family("atelier")
themes.clone("typeset-ink", "atelier", "atelier-expanded")

local neotheme = require("neotheme")
neotheme.setup({
	theme = "atelier-expanded",
	motion = false,
})
neotheme._register_commands()
vim.cmd.colorscheme("neotheme")

function _G.NeothemePaletteDemoStatusline()
	return "  Neotheme Palette  |  user family: atelier  |  private live preview  "
end

vim.o.statusline = "%!v:lua.NeothemePaletteDemoStatusline()"
