<div align="center">

<img src="assets/neotheme.svg" width="128" alt="Neotheme logo">

# neotheme.nvim

A semantic, palette-driven colorscheme for Neovim 0.12+.

[![CI](https://github.com/alsi-lawr/neotheme.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/alsi-lawr/neotheme.nvim/actions/workflows/ci.yml)
[![Neovim 0.12+](https://img.shields.io/badge/Neovim-0.12%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![MIT](https://img.shields.io/github/license/alsi-lawr/neotheme.nvim)](LICENSE)

</div>

Neotheme separates a theme's colors from the places Neovim uses them. A complete semantic palette drives editor UI, syntax, Tree-sitter, LSP, diagnostics, terminal colors, version control, markup, and opt-in plugin integrations. Themes stay coherent while individual roles remain easy to customize.

Built-in themes are organized into families. Each family keeps its complete inventory, visual examples, and lineage beside its source, while this README highlights one stand-out theme from every family.

## Why Neotheme

- One `:colorscheme neotheme` entrypoint for every built-in and custom theme.
- Semantic palette customization without copying a full colorscheme.
- Core Neovim, Tree-sitter, LSP, terminal, and Lualine support.
- Opt-in highlights for 15 plugins.
- Reproducible editor previews and palette references for every built-in theme.

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

## Theme families

| Family | Stand-out theme | Range | Full inventory |
| --- | --- | --- | --- |
| Gruber | `gruber-dark-muted` | Three dark and three light variants | [Themes, examples, and lineage](lua/neotheme/themes/gruber/README.md) |

### Gruber — Dark Muted

The current default: a restrained, warm dark theme with softened syntax colors and measured contrast.

**Editor preview**

![Gruber Dark Muted in Neovim](assets/gruber-dark-muted.png)

**Simplified palette**

![Gruber Dark Muted simplified palette](assets/gruber-dark-muted.svg)

Explore all six variants in the [Gruber family inventory](lua/neotheme/themes/gruber/README.md).

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

## License

MIT. See [LICENSE](LICENSE).
