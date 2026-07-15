# Typeset theme family

[<- neotheme.nvim](../../../../README.md)

The Typeset family treats code as one blue-black ink ageing across a printed page without imposing typography. Ordinary roles move through its dense body, oxidized violet-grey, dried sepia edges, and muted teal or olive residue. Stronger proofing red is reserved for focused signals. Paper uses newsprint surfaces with dark ink; Ink reverses that material relationship with warm paper text on a dark press-ink field.

## Themes

| Theme | Character | Background |
| --- | --- | --- |
| `typeset-paper` | Warm newsprint with an ageing blue-black ink hierarchy. | Light |
| `typeset-ink` | Blue-black press ink with a restrained warm-paper hierarchy. | Dark |

Select either variant during setup and keep the shared colorscheme entrypoint:

```lua
require("neotheme").setup({
	theme = "typeset-paper",
})

vim.cmd.colorscheme("neotheme")
```

## Visual inventory

Every editor preview uses the same integrated Neovim configuration. Each palette card shows the compact colors configured by that theme exactly once. Expanded semantic aliases are intentionally omitted.

### Typeset Paper

**Editor preview**

![Typeset Paper in Neovim](../../../../docs/theme/typeset/typeset-paper.png)

**Simplified palette**

![Typeset Paper simplified palette](../../../../docs/theme/typeset/typeset-paper.svg)

### Typeset Ink

**Editor preview**

![Typeset Ink in Neovim](../../../../docs/theme/typeset/typeset-ink.png)

**Simplified palette**

![Typeset Ink simplified palette](../../../../docs/theme/typeset/typeset-ink.svg)

The previews and palette cards can be reproduced with the repository's [asset scripts](../../../../assets/scripts/README.md).
