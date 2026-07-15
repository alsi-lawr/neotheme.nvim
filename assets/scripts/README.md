# Asset-generation scripts

Every script resolves the checkout from its own path, so it can be invoked from any working directory.

## Palette cards

`generate-palette-cards.sh` regenerates the checked-in SVG previews for built-in themes that use the `NeothemeSimplifiedPalette` schema. It locates the repository from the script's own path, so it can be invoked from any working directory in a checkout.

It requires Node.js 18 or newer. There are no package installation steps.

Generate every current card:

```sh
./assets/scripts/generate-palette-cards.sh
```

Generate only selected public themes:

```sh
./assets/scripts/generate-palette-cards.sh gruber-dark gruber-light
```

Verify that the checked-in cards match their theme definitions without changing files:

```sh
./assets/scripts/generate-palette-cards.sh --check
```

To run it while outside the repository root, use the path to the checkout's script, for example:

```sh
/path/to/neotheme.nvim/assets/scripts/generate-palette-cards.sh --check
```

The generator reads the direct color literals in each theme's `NeothemeSimplifiedPalette` input table, coalesces duplicate display colors, and emits one square tile for each resulting color under `docs/theme/<family>/`. Add a theme's public name, display name, asset directory, and source path to `generate-palette-cards.mjs` when adding another built-in simplified-palette preview.

## Live screenshots

`capture-theme-screenshots.sh` captures live Neovim previews under `docs/theme/<family>/`. It launches the user's normal Neovim configuration and applies a selected current theme only in that capture process. Before the regular init loads, the helper makes this checkout discoverable through both `runtimepath` and Lua module lookup, resets the Neovim Lua loader, and then opens the normal NvimTree layout. It uses `-i NONE` and `-n`, never writes the configured `init.lua`, and closes the temporary terminal after each screenshot. If Lualine is already loaded, the helper reapplies its existing runtime configuration so its theme is rendered after the colorscheme change.

The default capture backend needs a graphical KDE Linux session plus Neovim, Alacritty, Spectacle, and `qdbus`. Before each screenshot, a temporary KWin script finds the uniquely titled Neovim terminal and focuses that window by title; Spectacle therefore cannot fall through to an unrelated active GUI window. Pass `--nvim`, `--alacritty`, `--spectacle`, or `--qdbus` to select executable paths.

Capture every current public variant with the normal Neovim config:

```sh
./assets/scripts/capture-theme-screenshots.sh
```

Use a specific regular config, output directory, or selected variants:

```sh
./assets/scripts/capture-theme-screenshots.sh \
	--config ~/.config/nvim/init.lua \
	--output-dir /tmp/neotheme-previews \
	gruber-dark-muted gruber-light-muted
```

The script opens `lua/neotheme/init.lua` by default; choose another visible file with `--file`. `--columns`, `--lines`, `--timeout`, and `--settle` adjust the capture window and timing. Use `--no-lualine-refresh` when a regular configuration needs to retain its existing Lualine runtime state unchanged.

`--check` only verifies that requested PNG files exist; it cannot prove visual freshness because the screenshots intentionally reflect the selected regular Neovim configuration:

```sh
./assets/scripts/capture-theme-screenshots.sh --check
```
