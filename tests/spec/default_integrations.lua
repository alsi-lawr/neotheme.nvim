local h = dofile(NEOTHEME_TEST_ROOT .. "/tests/helpers.lua")

local groups = {
	"NvimTreeNormal",
	"CmpItemAbbrMatch",
	"BlinkCmpMenu",
	"TelescopeNormal",
	"FzfLuaNormal",
	"GitSignsAdd",
	"fugitiveHash",
	"SagaNormal",
	"RainbowDelimiterRed",
	"BufferLineFill",
	"LazyH1",
	"WhichKeyNormal",
	"TroubleNormal",
	"NoicePopup",
	"SnacksPicker",
}

for _, group in ipairs(groups) do
	h.falsy(h.group_exists(group), "minimal Neovim unexpectedly defines " .. group)
end

h.load()

for _, group in ipairs(groups) do
	h.falsy(h.group_exists(group), "default theme load must not define " .. group)
end
