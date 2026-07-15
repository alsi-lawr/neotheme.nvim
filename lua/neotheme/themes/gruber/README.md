# Gruber theme family

[← neotheme.nvim](../../../../README.md)

The Gruber family gives Neotheme six coordinated dark and light variants. They share a warm foundation and semantic structure, then vary brightness, contrast, and chroma to cover muted, balanced, and high-clarity environments.

## Themes

| Theme | Character | Background |
| --- | --- | --- |
| `gruber-dark-muted` | Restrained and warm. The Neotheme default. | Dark |
| `gruber-dark` | Balanced with clear contrast. | Dark |
| `gruber-darker` | Deep and high contrast. | Dark |
| `gruber-light` | Warm and paper-like. | Light |
| `gruber-lighter` | Bright and crisp. | Light |
| `gruber-light-muted` | Soft and lower chroma. | Light |

Select any variant during setup and keep the shared colorscheme entrypoint:

```lua
require("neotheme").setup({
	theme = "gruber-dark-muted",
})

vim.cmd.colorscheme("neotheme")
```

## Visual inventory

Every editor preview uses the same integrated Neovim configuration. Each palette card shows the compact colors configured by that theme exactly once. Expanded semantic aliases are intentionally omitted.

### Gruber Dark Muted

**Editor preview**

![Gruber Dark Muted in Neovim](../../../../assets/gruber-dark-muted.png)

**Simplified palette**

![Gruber Dark Muted simplified palette](../../../../assets/gruber-dark-muted.svg)

### Gruber Dark

**Editor preview**

![Gruber Dark in Neovim](../../../../assets/gruber-dark.png)

**Simplified palette**

![Gruber Dark simplified palette](../../../../assets/gruber-dark.svg)

### Gruber Darker

**Editor preview**

![Gruber Darker in Neovim](../../../../assets/gruber-darker.png)

**Simplified palette**

![Gruber Darker simplified palette](../../../../assets/gruber-darker.svg)

### Gruber Light

**Editor preview**

![Gruber Light in Neovim](../../../../assets/gruber-light.png)

**Simplified palette**

![Gruber Light simplified palette](../../../../assets/gruber-light.svg)

### Gruber Lighter

**Editor preview**

![Gruber Lighter in Neovim](../../../../assets/gruber-lighter.png)

**Simplified palette**

![Gruber Lighter simplified palette](../../../../assets/gruber-lighter.svg)

### Gruber Light Muted

**Editor preview**

![Gruber Light Muted in Neovim](../../../../assets/gruber-light-muted.png)

**Simplified palette**

![Gruber Light Muted simplified palette](../../../../assets/gruber-light-muted.svg)

The previews and palette cards can be reproduced with the repository's [asset scripts](../../../../assets/scripts/README.md).

## Lineage

The Gruber family builds on [blazkowolf/gruber-darker.nvim](https://github.com/blazkowolf/gruber-darker.nvim) and the work that established its Neovim foundation.

Its palette lineage also includes [rexim/gruber-darker-theme](https://github.com/rexim/gruber-darker-theme), [drsooch/gruber-darker-vim](https://github.com/drsooch/gruber-darker-vim), [Jim Blevins' Emacs port](https://jblevins.org/projects/emacs-color-themes/gruber-darker-theme.el.html), and John Gruber's original [BBEdit Gruber Dark scheme](https://daringfireball.net/projects/bbcolors/schemes/).
