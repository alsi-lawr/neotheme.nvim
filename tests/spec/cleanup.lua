local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")

h.load()

local autocmds = vim.api.nvim_get_autocmds({ group = "Neotheme" })
h.truthy(#autocmds > 0, "theme autocmd group should exist while active")

vim.cmd.colorscheme("default")

local ok = pcall(vim.api.nvim_get_autocmds, { group = "Neotheme" })
h.falsy(ok, "theme autocmd group should be deleted after switching colorschemes")
