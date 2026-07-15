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
| Arcfield | `arcfield-graphite` | Two dark and one light variant | [Themes and examples](docs/themes/arcfield/README.md) |
| Bathyal | `bathyal-midwater` | Two dark and one light variant | [Themes and examples](docs/themes/bathyal/README.md) |
| Ferric | `ferric-forge` | One dark and one light variant | [Themes and examples](docs/themes/ferric/README.md) |
| Gruber | `gruber-dark-muted` | Three dark and three light variants | [Themes, examples, and lineage](docs/themes/gruber/README.md) |
| Neritic | `neritic-day` | Two dark and two light variants | [Themes and examples](docs/themes/neritic/README.md) |
| Typeset | `typeset-paper` | One light and one dark variant | [Themes and examples](docs/themes/typeset/README.md) |
| Typewriter | `typewriter-ink` | Three light and two dark variants | [Themes and examples](docs/themes/typewriter/README.md) |
| Understory | `understory-canopy` | Two dark and two light variants | [Themes and examples](docs/themes/understory/README.md) |

### Arcfield - Graphite

An electrified storm-dark theme with graphite-blue fields, cyan control flow, blue-white callables, and restrained strike-yellow member and literal flashes.

**Editor preview**

![Arcfield Graphite in Neovim](docs/theme/arcfield/arcfield-graphite.png)

**Simplified palette**

![Arcfield Graphite simplified palette](docs/theme/arcfield/arcfield-graphite.svg)

Explore all three variants in the [Arcfield family inventory](docs/themes/arcfield/README.md).

### Bathyal - Midwater

A near-black pressure-blue theme with cold pale text and sparse cyan, violet, green, and muted-red accents.

**Editor preview**

![Bathyal Midwater in Neovim](docs/theme/bathyal/bathyal-midwater.png)

**Simplified palette**

![Bathyal Midwater simplified palette](docs/theme/bathyal/bathyal-midwater.svg)

Explore all three variants in the [Bathyal family inventory](docs/themes/bathyal/README.md).

### Ferric - Forge

An industrial dark theme with charcoal and steel surfaces, pale metal text, iron-rust accents, rusty copper details, and restrained verdigris.

**Editor preview**

![Ferric Forge in Neovim](docs/theme/ferric/ferric-forge.png)

**Simplified palette**

![Ferric Forge simplified palette](docs/theme/ferric/ferric-forge.svg)

Explore both variants in the [Ferric family inventory](docs/themes/ferric/README.md).

### Gruber - Dark Muted

The current default: a restrained, warm dark theme with softened syntax colors and measured contrast.

**Editor preview**

![Gruber Dark Muted in Neovim](docs/theme/gruber/gruber-dark-muted.png)

**Simplified palette**

![Gruber Dark Muted simplified palette](docs/theme/gruber/gruber-dark-muted.svg)

Explore all six variants in the [Gruber family inventory](docs/themes/gruber/README.md).

### Neritic - Day

A clear coastal light theme with turquoise and fog surfaces, deep-ocean text, sea-glass greens, and sunlit coral accents.

**Editor preview**

![Neritic Day in Neovim](docs/theme/neritic/neritic-day.png)

**Simplified palette**

![Neritic Day simplified palette](docs/theme/neritic/neritic-day.svg)

Explore all four variants in the [Neritic family inventory](docs/themes/neritic/README.md).

### Typeset - Paper

A warm newsprint theme whose ordinary syntax follows one ageing blue-black ink through violet-grey oxidation, dried sepia edges, and muted residue. Stronger proofing color remains sparse.

**Editor preview**

![Typeset Paper in Neovim](docs/theme/typeset/typeset-paper.png)

**Simplified palette**

![Typeset Paper simplified palette](docs/theme/typeset/typeset-paper.svg)

Explore both variants in the [Typeset family inventory](docs/themes/typeset/README.md).

### Typewriter - Ink

A crisp paper light theme with near-black ink, strong neutral separation, and restrained color reserved for focused signals.

**Editor preview**

![Typewriter Ink in Neovim](docs/theme/typewriter/typewriter-ink.png)

**Simplified palette**

![Typewriter Ink simplified palette](docs/theme/typewriter/typewriter-ink.svg)

Explore all five variants in the [Typewriter family inventory](docs/themes/typewriter/README.md).

### Understory - Canopy

A canopy-filtered dark theme with cool forest shadows, pine-green structure, and distinct moss, fern, lichen, bark, and amber details.

**Editor preview**

![Understory Canopy in Neovim](docs/theme/understory/understory-canopy.png)

**Simplified palette**

![Understory Canopy simplified palette](docs/theme/understory/understory-canopy.svg)

Explore all four variants in the [Understory family inventory](docs/themes/understory/README.md).

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
