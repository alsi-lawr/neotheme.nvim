local root = assert(vim.env.NEOTHEME_CAPTURE_ROOT, "NEOTHEME_CAPTURE_ROOT is required")
local theme_name = assert(vim.env.NEOTHEME_CAPTURE_THEME, "NEOTHEME_CAPTURE_THEME is required")
local capture_file = assert(vim.env.NEOTHEME_CAPTURE_FILE, "NEOTHEME_CAPTURE_FILE is required")
local ready_file =
	assert(vim.env.NEOTHEME_CAPTURE_READY_FILE, "NEOTHEME_CAPTURE_READY_FILE is required")
local error_file =
	assert(vim.env.NEOTHEME_CAPTURE_ERROR_FILE, "NEOTHEME_CAPTURE_ERROR_FILE is required")
local refresh_lualine = vim.env.NEOTHEME_CAPTURE_REFRESH_LUALINE ~= "false"

local function configure_checkout_lookup()
	-- These changes are process-local and happen before the regular init.lua loads.
	vim.opt.runtimepath:prepend(root)
	package.path =
		table.concat({ root .. "/lua/?.lua", root .. "/lua/?/init.lua", package.path }, ";")

	if vim.loader then
		if type(vim.loader.reset) == "function" then
			vim.loader.reset(root)
		end
		vim.loader.disable()
	end
end

local function clear_neotheme_modules()
	local loaded_names = {}
	for name in pairs(package.loaded) do
		if name == "neotheme" or name:match("^neotheme%.") then
			table.insert(loaded_names, name)
		end
	end
	for _, name in ipairs(loaded_names) do
		package.loaded[name] = nil
	end
end

configure_checkout_lookup()
clear_neotheme_modules()

local function refresh_loaded_lualine()
	if not refresh_lualine then
		return
	end

	local ok, lualine = pcall(require, "lualine")
	if not ok then
		return
	end

	if type(lualine.get_config) == "function" and type(lualine.setup) == "function" then
		lualine.setup(lualine.get_config())
	end
	if type(lualine.refresh) == "function" then
		lualine.refresh({ force = true, scope = "all" })
	end
end

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.schedule(function()
			local ok, err = xpcall(function()
				configure_checkout_lookup()
				clear_neotheme_modules()

				local options = require("neotheme.config").get()
				options.theme = theme_name
				require("neotheme").setup(options)
				vim.cmd.colorscheme("neotheme")

				local refreshed, refresh_error = pcall(refresh_loaded_lualine)
				if not refreshed then
					vim.notify(refresh_error, vim.log.levels.WARN)
				end

				vim.cmd.edit(capture_file)
				local tree_opened = pcall(vim.cmd, "NvimTreeOpen")
				if tree_opened then
					vim.cmd("wincmd p")
				end
				vim.cmd.redrawstatus()
				vim.cmd.redrawtabline()
			end, debug.traceback)

			if not ok then
				vim.fn.writefile({ err }, error_file)
				vim.notify(err, vim.log.levels.ERROR)
				return
			end

			vim.fn.writefile({ theme_name }, ready_file)
		end)
	end,
})
