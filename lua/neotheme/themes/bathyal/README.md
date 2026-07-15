# Bathyal theme family

[<- neotheme.nvim](../../../../README.md)

The Bathyal family takes its identity from the permanently dark, cold, high-pressure deep ocean rather than shallower coastal water. Near-black pressure-blue variants keep luminous accents selective, while Marine Snow translates the same submerged character into a pale blue-gray and off-white palette.

## Themes

| Theme | Character | Background |
| --- | --- | --- |
| `bathyal-midwater` | Near-black, cold, and restrained with sparse cyan, violet, green, and muted-red accents. | Dark |
| `bathyal-marine-snow` | Pale and particulate with subdued organic and mineral colors. | Light |
| `bathyal-bioluminescence` | Focused blue, cyan, and green signals with strong semantic separation. | Dark |

Select any variant during setup and keep the shared colorscheme entrypoint:

```lua
require("neotheme").setup({
	theme = "bathyal-midwater",
})

vim.cmd.colorscheme("neotheme")
```

## Visual inventory

Every editor preview uses the same integrated Neovim configuration. Each palette card shows the compact colors configured by that theme exactly once. Expanded semantic aliases are intentionally omitted.

### Bathyal Midwater

**Editor preview**

![Bathyal Midwater in Neovim](../../../../docs/theme/bathyal/bathyal-midwater.png)

**Simplified palette**

![Bathyal Midwater simplified palette](../../../../docs/theme/bathyal/bathyal-midwater.svg)

### Bathyal Marine Snow

**Editor preview**

![Bathyal Marine Snow in Neovim](../../../../docs/theme/bathyal/bathyal-marine-snow.png)

**Simplified palette**

![Bathyal Marine Snow simplified palette](../../../../docs/theme/bathyal/bathyal-marine-snow.svg)

### Bathyal Bioluminescence

**Editor preview**

![Bathyal Bioluminescence in Neovim](../../../../docs/theme/bathyal/bathyal-bioluminescence.png)

**Simplified palette**

![Bathyal Bioluminescence simplified palette](../../../../docs/theme/bathyal/bathyal-bioluminescence.svg)

The previews and palette cards can be reproduced with the repository's [asset scripts](../../../../assets/scripts/README.md).
