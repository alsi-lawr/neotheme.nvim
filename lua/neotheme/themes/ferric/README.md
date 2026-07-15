# Ferric theme family

[<- neotheme.nvim](../../../../README.md)

The Ferric family gives Neotheme coordinated dark and light industrial themes. Forge uses charcoal and steel surfaces with pale metal text, iron-rust accents, rusty copper details, and restrained verdigris. Patina carries the same rust and steel semantics onto pale oxidized surfaces.

## Themes

| Theme | Character | Background |
| --- | --- | --- |
| `ferric-forge` | Charcoal iron with pale steel text and rust accents. | Dark |
| `ferric-patina` | Pale oxidized steel with dark iron text and shared rust accents. | Light |

Select either variant during setup and keep the shared colorscheme entrypoint:

```lua
require("neotheme").setup({
	theme = "ferric-forge",
})

vim.cmd.colorscheme("neotheme")
```

## Visual inventory

Every editor preview uses the same integrated Neovim configuration. Each palette card shows the compact colors configured by that theme exactly once. Expanded semantic aliases are intentionally omitted.

### Ferric Forge

**Editor preview**

![Ferric Forge in Neovim](../../../../docs/theme/ferric/ferric-forge.png)

**Simplified palette**

![Ferric Forge simplified palette](../../../../docs/theme/ferric/ferric-forge.svg)

### Ferric Patina

**Editor preview**

![Ferric Patina in Neovim](../../../../docs/theme/ferric/ferric-patina.png)

**Simplified palette**

![Ferric Patina simplified palette](../../../../docs/theme/ferric/ferric-patina.svg)

The previews and palette cards can be reproduced with the repository's [asset scripts](../../../../assets/scripts/README.md).
