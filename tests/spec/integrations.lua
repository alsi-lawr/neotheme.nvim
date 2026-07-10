local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")
local engine = require("neotheme")

local cases = {
	{ option = "nvim_tree", group = "NvimTreeGitFolderStagedHL", plugin = "nvim-tree" },
	{ option = "cmp", group = "CmpItemAbbrMatch", plugin = "cmp" },
	{ option = "blink_cmp", group = "BlinkCmpMenu", plugin = "blink.cmp" },
	{ option = "telescope", group = "TelescopePromptNormal", plugin = "telescope" },
	{ option = "fzf_lua", group = "FzfLuaFzfMatch", plugin = "fzf-lua" },
	{ option = "gitsigns", group = "GitSignsAdd", plugin = "gitsigns" },
	{ option = "fugitive", group = "fugitiveHash", plugin = "fugitive" },
	{ option = "lspsaga", group = "SagaNormal", plugin = "lspsaga" },
	{ option = "rainbow_delimiters", group = "RainbowDelimiterRed", plugin = "rainbow-delimiters" },
	{ option = "bufferline", group = "BufferLineFill", plugin = "bufferline" },
	{ option = "lazy", group = "LazyH1", plugin = "lazy" },
	{ option = "which_key", group = "WhichKeyNormal", plugin = "which-key" },
	{ option = "trouble", group = "TroubleNormal", plugin = "trouble" },
	{ option = "noice", group = "NoiceCmdlinePopupBorder", plugin = "noice" },
	{ option = "snacks", group = "SnacksPicker", plugin = "snacks" },
}

for _, case in ipairs(cases) do
	package.preload[case.plugin] = function()
		error("theme attempted to load plugin module " .. case.plugin)
	end
	h.falsy(h.group_exists(case.group), "integration group exists before enable: " .. case.group)
	h.load({ integrations = { [case.option] = true } })
	h.truthy(h.group_exists(case.group), "integration group is missing after enable: " .. case.group)
	h.eq(nil, package.loaded[case.plugin], "theme must not load plugin module " .. case.plugin)
end

local nvim_tree_groups = {
	"NvimTreeNormal",
	"NvimTreeExecFile",
	"NvimTreeFolderName",
	"NvimTreeFolderIcon",
	"NvimTreeGitFileDirtyHL",
	"NvimTreeGitFolderStagedHL",
	"NvimTreeDiagnosticErrorIcon",
	"NvimTreeDiagnosticWarnFileHL",
	"NvimTreeDiagnosticHintFolderHL",
	"NvimTreeCopiedHL",
	"NvimTreeCutHL",
	"NvimTreeModifiedIcon",
	"NvimTreeModifiedFileHL",
	"NvimTreeModifiedFolderHL",
	"NvimTreeHiddenIcon",
	"NvimTreeHiddenFileHL",
	"NvimTreeHiddenFolderHL",
	"NvimTreeHiddenDisplay",
	"NvimTreeOpenedHL",
	"NvimTreeWindowPicker",
}

local nvim_tree_definitions = require("neotheme.integrations.nvim_tree").get(engine.palette())
for _, group in ipairs(nvim_tree_groups) do
	h.truthy(nvim_tree_definitions[group], "nvim-tree category coverage is missing " .. group)
end
h.eq(
	nvim_tree_definitions.NvimTreeClosedFolderIcon,
	nvim_tree_definitions.NvimTreeOpenedFolderIcon,
	"nvim-tree folder icon color must not change when opened"
)
h.eq(
	nvim_tree_definitions.NvimTreeFolderArrowClosed,
	nvim_tree_definitions.NvimTreeFolderArrowOpen,
	"nvim-tree folder arrow color must not change when opened"
)

h.load({
	configure_palette = function(configured)
		configured.ui.search = configured.diagnostic.error
	end,
	integrations = { telescope = true },
})
h.eq(
	h.color(require("neotheme").palette().diagnostic.error),
	h.highlight("TelescopeMatching").fg,
	"configured palette reaches integrations"
)
