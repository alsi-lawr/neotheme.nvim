<div align="center">

<img src="assets/neotheme.svg" width="128" alt="Neotheme logo">

# neotheme.nvim

A semantic, palette-driven colorscheme for Neovim 0.12+.

[![CI](https://github.com/alsi-lawr/neotheme.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/alsi-lawr/neotheme.nvim/actions/workflows/ci.yml)
[![Neovim 0.12+](https://img.shields.io/badge/Neovim-0.12%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![MIT](https://img.shields.io/github/license/alsi-lawr/neotheme.nvim)](LICENSE)

</div>

Neotheme separates a theme's colors from the places Neovim uses them. A complete semantic palette drives editor UI, syntax, Tree-sitter, LSP, diagnostics, terminal colors, version control, markup, and opt-in plugin integrations. Themes stay coherent while individual roles remain easy to customize.

Built-in themes are organized into families. Each family keeps its complete inventory and visual examples under `docs/themes/`; Gruber also preserves its lineage attribution. This README highlights one stand-out theme from every family.

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
| Arcfield | `arcfield-graphite` | Two dark and one light variant | [Themes and examples](docs/themes/arcfield/README.md) |
| Bathyal | `bathyal-midwater` | Two dark and one light variant | [Themes and examples](docs/themes/bathyal/README.md) |
| Ferric | `ferric-forge` | One dark and one light variant | [Themes and examples](docs/themes/ferric/README.md) |
| Grove | `grove-campfire` | One dark and one light variant | [Themes and examples](docs/themes/grove/README.md) |
| Gruber | `gruber-dark-muted` | Three dark and three light variants | [Themes, examples, and lineage](docs/themes/gruber/README.md) |
| Neritic | `neritic-day` | Two dark and two light variants | [Themes and examples](docs/themes/neritic/README.md) |
| Typeset | `typeset-paper` | One light and one dark variant | [Themes and examples](docs/themes/typeset/README.md) |
| Typewriter | `typewriter-ink` | Three light and two dark variants | [Themes and examples](docs/themes/typewriter/README.md) |
| Understory | `understory-canopy` | Two dark and two light variants | [Themes and examples](docs/themes/understory/README.md) |

## Family previews

<table>
<tr>
<td align="center" valign="top">
<strong><a href="docs/themes/arcfield/README.md">Arcfield - Graphite</a></strong><br>
<sub>An electrified storm-dark theme with near-black fields, cyan discharge, blue-white callables, and strike-yellow details.</sub><br><br>
<a href="docs/themes/arcfield/arcfield-graphite.png"><img src="docs/themes/arcfield/arcfield-graphite.png" width="320" alt="Arcfield - Graphite editor preview"></a>
<a href="docs/themes/arcfield/arcfield-graphite.svg"><img src="docs/themes/arcfield/arcfield-graphite.svg" width="240" alt="Arcfield - Graphite simplified palette"></a>
</td>
<td align="center" valign="top">
<strong><a href="docs/themes/bathyal/README.md">Bathyal - Midwater</a></strong><br>
<sub>A near-black pressure-blue theme with cold pale text and sparse deep-ocean signals.</sub><br><br>
<a href="docs/themes/bathyal/bathyal-midwater.png"><img src="docs/themes/bathyal/bathyal-midwater.png" width="320" alt="Bathyal - Midwater editor preview"></a>
<a href="docs/themes/bathyal/bathyal-midwater.svg"><img src="docs/themes/bathyal/bathyal-midwater.svg" width="240" alt="Bathyal - Midwater simplified palette"></a>
</td>
<td align="center" valign="top">
<strong><a href="docs/themes/ferric/README.md">Ferric - Forge</a></strong><br>
<sub>Charcoal iron and steel with rust, copper, and restrained verdigris.</sub><br><br>
<a href="docs/themes/ferric/ferric-forge.png"><img src="docs/themes/ferric/ferric-forge.png" width="320" alt="Ferric - Forge editor preview"></a>
<a href="docs/themes/ferric/ferric-forge.svg"><img src="docs/themes/ferric/ferric-forge.svg" width="240" alt="Ferric - Forge simplified palette"></a>
</td>
<td align="center" valign="top">
<strong><a href="docs/themes/grove/README.md">Grove - Campfire</a></strong><br>
<sub>Leafy forest-dark fantasy with parchment, marigold, moss, foxglove, mallow, peony, and poppy.</sub><br><br>
<a href="docs/themes/grove/grove-campfire.png"><img src="docs/themes/grove/grove-campfire.png" width="320" alt="Grove - Campfire editor preview"></a>
<a href="docs/themes/grove/grove-campfire.svg"><img src="docs/themes/grove/grove-campfire.svg" width="240" alt="Grove - Campfire simplified palette"></a>
</td>
<td align="center" valign="top">
<strong><a href="docs/themes/gruber/README.md">Gruber - Dark Muted</a></strong><br>
<sub>The warm, restrained default with softened syntax colors and measured contrast.</sub><br><br>
<a href="docs/themes/gruber/gruber-dark-muted.png"><img src="docs/themes/gruber/gruber-dark-muted.png" width="320" alt="Gruber - Dark Muted editor preview"></a>
<a href="docs/themes/gruber/gruber-dark-muted.svg"><img src="docs/themes/gruber/gruber-dark-muted.svg" width="240" alt="Gruber - Dark Muted simplified palette"></a>
</td>
<td align="center" valign="top">
<strong><a href="docs/themes/neritic/README.md">Neritic - Day</a></strong><br>
<sub>Turquoise coastal light with deep-ocean text, sea glass, algae, and coral.</sub><br><br>
<a href="docs/themes/neritic/neritic-day.png"><img src="docs/themes/neritic/neritic-day.png" width="320" alt="Neritic - Day editor preview"></a>
<a href="docs/themes/neritic/neritic-day.svg"><img src="docs/themes/neritic/neritic-day.svg" width="240" alt="Neritic - Day simplified palette"></a>
</td>
<td align="center" valign="top">
<strong><a href="docs/themes/typeset/README.md">Typeset - Paper</a></strong><br>
<sub>Warm newsprint carrying ageing blue-black ink, oxidized violet-grey, sepia, and muted residue.</sub><br><br>
<a href="docs/themes/typeset/typeset-paper.png"><img src="docs/themes/typeset/typeset-paper.png" width="320" alt="Typeset - Paper editor preview"></a>
<a href="docs/themes/typeset/typeset-paper.svg"><img src="docs/themes/typeset/typeset-paper.svg" width="240" alt="Typeset - Paper simplified palette"></a>
</td>
<td align="center" valign="top">
<strong><a href="docs/themes/typewriter/README.md">Typewriter - Ink</a></strong><br>
<sub>Crisp paper and near-black ink with strong neutral separation.</sub><br><br>
<a href="docs/themes/typewriter/typewriter-ink.png"><img src="docs/themes/typewriter/typewriter-ink.png" width="320" alt="Typewriter - Ink editor preview"></a>
<a href="docs/themes/typewriter/typewriter-ink.svg"><img src="docs/themes/typewriter/typewriter-ink.svg" width="240" alt="Typewriter - Ink simplified palette"></a>
</td>
<td align="center" valign="top">
<strong><a href="docs/themes/understory/README.md">Understory - Canopy</a></strong><br>
<sub>Canopy-filtered forest shadow with pine, moss, fern, lichen, bark, and amber.</sub><br><br>
<a href="docs/themes/understory/understory-canopy.png"><img src="docs/themes/understory/understory-canopy.png" width="320" alt="Understory - Canopy editor preview"></a>
<a href="docs/themes/understory/understory-canopy.svg"><img src="docs/themes/understory/understory-canopy.svg" width="240" alt="Understory - Canopy simplified palette"></a>
</td>
</tr>
</table>

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
