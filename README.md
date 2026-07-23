<div align="center">

<img src="docs/assets/neotheme.svg" width="128" alt="Neotheme logo">

# neotheme.nvim

A palette-based colorscheme for Neovim 0.12+.

[![CI](https://github.com/alsi-lawr/neotheme.nvim/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/alsi-lawr/neotheme.nvim/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/alsi-lawr/neotheme.nvim?display_name=tag&sort=semver)](https://github.com/alsi-lawr/neotheme.nvim/releases/latest)

</div>

Neotheme includes 31 dark and light themes, a theme browser, session switching, a palette editor,
terminal colours, Lualine support, and optional plugin integrations.

## Installation

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

The default theme is `gruber-dark-muted`. Run `:Neotheme` to browse themes and
`:NeothemePalette` to create or edit local palettes.

## Palette packs

[`neotheme-packs.nvim`](https://github.com/alsi-lawr/neotheme-packs.nvim) adds opt-in curated
themes. See
[Palette Providers](https://github.com/alsi-lawr/neotheme.nvim/wiki/Palette-Providers) for setup and
behaviour.

## Previews

<div align="center">

<h3>Theme browser</h3>

<img src="docs/assets/neotheme-browser.webp" alt="Neotheme family browser">

<h3>Theme families</h3>

<img src="docs/themes/theme-family-previews.webp" alt="Theme family previews">

<p><a href="docs/themes/theme-family-matrix.webp">Open the full-size theme matrix</a>.</p>

</div>

## Documentation

- [Getting started](https://github.com/alsi-lawr/neotheme.nvim/wiki/Getting-Started)
- [Configuration](https://github.com/alsi-lawr/neotheme.nvim/wiki/Configuration)
- [Themes and session controls](https://github.com/alsi-lawr/neotheme.nvim/wiki/Themes)
- [Palette workspace](https://github.com/alsi-lawr/neotheme.nvim/wiki/Palette-Workspace)
- [Palette customization](https://github.com/alsi-lawr/neotheme.nvim/wiki/Palette-Customization)
- [Integrations](https://github.com/alsi-lawr/neotheme.nvim/wiki/Integrations)
- [API](https://github.com/alsi-lawr/neotheme.nvim/wiki/API)
- [Troubleshooting](https://github.com/alsi-lawr/neotheme.nvim/wiki/Troubleshooting)

## Development

Run `stylua --check .` and `./tests/run.sh` from the repository root. See the
[development guide](https://github.com/alsi-lawr/neotheme.nvim/wiki/Development) for repository and
preview-generation details.

## License

MIT. See [LICENSE](LICENSE).
