vim.opt.loadplugins = false

local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(source))

_G.NEOTHEME_TEST_ROOT = root
vim.opt.runtimepath:prepend(root)
