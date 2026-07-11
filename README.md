<div align="center">

# neotheme.nvim

A semantic, palette-driven colorscheme for Neovim 0.12+ with six curated Gruber variants.

[![CI](https://github.com/alsi-lawr/neotheme.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/alsi-lawr/neotheme.nvim/actions/workflows/ci.yml)
[![Neovim 0.12+](https://img.shields.io/badge/Neovim-0.12%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![MIT](https://img.shields.io/github/license/alsi-lawr/neotheme.nvim)](LICENSE)

</div>

Neotheme separates colors from the places Neovim uses them. A complete semantic palette drives editor UI, syntax, Tree-sitter, LSP, diagnostics, terminal colors, version control, markup, and opt-in plugin integrations. Themes stay coherent while individual roles remain easy to customize.

## Why Neotheme

- Six coordinated dark and light Gruber variants.
- One `:colorscheme neotheme` entrypoint for every built-in and custom theme.
- Semantic palette customization without copying a full colorscheme.
- Core Neovim, Tree-sitter, LSP, terminal, and Lualine support.
- Opt-in highlights for 15 plugins.

## Quick start

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
	"alsi-lawr/neotheme.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("neotheme").setup()
		vim.cmd.colorscheme("neotheme")
	end,
}
```

The default theme is `gruber-dark-muted`. Select another theme during setup and keep the same colorscheme command:

```lua
require("neotheme").setup({
	theme = "gruber-light",
})

vim.cmd.colorscheme("neotheme")
```

See the [Neotheme wiki](https://github.com/alsi-lawr/neotheme.nvim/wiki) for installation alternatives, every option, integrations, palette customization, and the public API.

## Themes

| Theme | Character | Background |
| --- | --- | --- |
| `gruber-dark-muted` | Restrained and warm. The default. | Dark |
| `gruber-dark` | Balanced with clear contrast. | Dark |
| `gruber-darker` | Deep and high contrast. | Dark |
| `gruber-light` | Warm and paper-like. | Light |
| `gruber-lighter` | Bright and crisp. | Light |
| `gruber-light-muted` | Soft and lower chroma. | Light |

## Visual inventory

Every editor preview uses the same integrated Neovim configuration. Each palette card shows the compact colors configured by that theme exactly once. Expanded semantic aliases are intentionally omitted.

### Gruber Dark Muted (default)

**Editor preview**

![Gruber Dark Muted in Neovim](assets/gruber-dark-muted.png)

**Simplified palette**

![Gruber Dark Muted simplified palette](assets/gruber-dark-muted.svg)

### Gruber Dark

**Editor preview**

![Gruber Dark in Neovim](assets/gruber-dark.png)

**Simplified palette**

![Gruber Dark simplified palette](assets/gruber-dark.svg)

### Gruber Darker

**Editor preview**

![Gruber Darker in Neovim](assets/gruber-darker.png)

**Simplified palette**

![Gruber Darker simplified palette](assets/gruber-darker.svg)

### Gruber Light

**Editor preview**

![Gruber Light in Neovim](assets/gruber-light.png)

**Simplified palette**

![Gruber Light simplified palette](assets/gruber-light.svg)

### Gruber Lighter

**Editor preview**

![Gruber Lighter in Neovim](assets/gruber-lighter.png)

**Simplified palette**

![Gruber Lighter simplified palette](assets/gruber-lighter.svg)

### Gruber Light Muted

**Editor preview**

![Gruber Light Muted in Neovim](assets/gruber-light-muted.png)

**Simplified palette**

![Gruber Light Muted simplified palette](assets/gruber-light-muted.svg)

## Customize semantic roles

`configure_palette` receives the selected theme's complete semantic palette before highlights are applied:

```lua
require("neotheme").setup({
	theme = "gruber-dark",
	configure_palette = function(palette)
		palette.ui.accent = palette.syntax.function_name
		palette.diagnostic.warning = palette.syntax.keyword
	end,
	integrations = {
		gitsigns = true,
		nvim_tree = true,
		telescope = true,
	},
})
```

The configurator mutates its argument and returns nothing. Neotheme validates supplied categories, fields, and `#RRGGBB` values.

## Development

Run the formatter and headless Neovim test suite from the repository root:

```sh
stylua --check .
./tests/run.sh
```

Documentation previews are reproducible with the portable tools in [assets/scripts](assets/scripts/README.md):

```sh
./assets/scripts/generate-palette-cards.sh
./assets/scripts/capture-theme-screenshots.sh
```

## Acknowledgements

The Gruber family builds on [blazkowolf/gruber-darker.nvim](https://github.com/blazkowolf/gruber-darker.nvim) and the work that established its Neovim foundation.

The palette lineage also includes [rexim/gruber-darker-theme](https://github.com/rexim/gruber-darker-theme), [drsooch/gruber-darker-vim](https://github.com/drsooch/gruber-darker-vim), [Jim Blevins' Emacs port](https://jblevins.org/projects/emacs-color-themes/gruber-darker-theme.el.html), and John Gruber's original [BBEdit Gruber Dark scheme](https://daringfireball.net/projects/bbcolors/schemes/).

## License

MIT. See [LICENSE](LICENSE).
