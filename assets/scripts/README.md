# Asset-generation scripts

Every script resolves the checkout from its own path, so it can be invoked from any working directory.

## Final theme assets

`generate-theme-assets.sh` is the public asset pipeline. For the root family overview and for every family, it leaves exactly two final files: a static editor-and-palette matrix and an animated 30 FPS WebP carousel. Temporary editor screenshots and palette cards are generated in a disposable working directory and removed when composition finishes.

It requires Node.js 18 or newer, FFmpeg with `libwebp` and `libwebp_anim`, GNU `timeout`, and a Chromium-compatible browser. Live screenshot capture additionally needs the KDE tools described below.

Generate every final asset:

```sh
./assets/scripts/generate-theme-assets.sh
```

Recompose from an existing flat directory of temporary `<theme>.png` and `<theme>.svg` inputs without recapturing:

```sh
./assets/scripts/generate-theme-assets.sh --source-dir /path/to/theme-inputs
```

Pass `--check` with `--source-dir` to regenerate in scratch space and verify the checked-in matrix and carousel files byte for byte.

## Intermediate palette cards

`generate-palette-cards.sh` creates the temporary SVG inputs used by the final asset pipeline for built-in themes that use the `NeothemeSimplifiedPalette` schema. It locates the repository from the script's own path, so it can be invoked from any working directory in a checkout.

It requires Node.js 18 or newer. There are no package installation steps.

Generate every current card in a temporary source directory:

```sh
./assets/scripts/generate-palette-cards.sh --output-dir /path/to/theme-inputs
```

Generate only selected public themes:

```sh
./assets/scripts/generate-palette-cards.sh \
	--output-dir /tmp/neotheme-theme-inputs \
	gruber-dark gruber-light
```

Verify cards in a selected output directory without changing files:

```sh
./assets/scripts/generate-palette-cards.sh --check --output-dir /path/to/theme-inputs
```

To run it while outside the repository root, use the path to the checkout's script, for example:

```sh
/path/to/neotheme.nvim/assets/scripts/generate-palette-cards.sh --output-dir /path/to/theme-inputs
```

The generator reads the direct color literals in each registered theme's `NeothemeSimplifiedPalette` input table, coalesces duplicate display colors, and emits one square tile for each resulting color. Theme names and source modules come from the runtime theme registry, so adding a registered simplified-palette theme does not require another asset manifest.

## Live screenshots

`capture-theme-screenshots.sh` captures the temporary live Neovim inputs consumed by the final asset pipeline. It launches the user's normal Neovim configuration and applies a selected current theme only in that capture process. Before the regular init loads, the helper makes this checkout discoverable through both `runtimepath` and Lua module lookup, resets the Neovim Lua loader, and then opens the normal NvimTree layout. It uses `-i NONE` and `-n`, never writes the configured `init.lua`, and closes the temporary terminal after each screenshot. If Lualine is already loaded, the helper reapplies its existing runtime configuration so its theme is rendered after the colorscheme change.

The default capture backend needs a graphical KDE Linux session plus Neovim, Alacritty, Spectacle, and `qdbus`. Before each screenshot, a temporary KWin script finds the uniquely titled Neovim terminal and focuses that window by title; Spectacle therefore cannot fall through to an unrelated active GUI window. Pass `--nvim`, `--alacritty`, `--spectacle`, or `--qdbus` to select executable paths.

Capture every current public variant with the normal Neovim config:

```sh
./assets/scripts/capture-theme-screenshots.sh \
	--output-dir /tmp/neotheme-theme-inputs
```

Use a specific regular config, output directory, or selected variants:

```sh
./assets/scripts/capture-theme-screenshots.sh \
	--config ~/.config/nvim/init.lua \
	--output-dir /tmp/neotheme-theme-inputs \
	gruber-dark-muted gruber-light-muted
```

The script opens `lua/neotheme/init.lua` by default; choose another visible file with `--file`. `--columns`, `--lines`, `--timeout`, and `--settle` adjust the capture window and timing. Use `--no-lualine-refresh` when a regular configuration needs to retain its existing Lualine runtime state unchanged.

`--check` only verifies that requested PNG files exist; it cannot prove visual freshness because the screenshots intentionally reflect the selected regular Neovim configuration:

```sh
./assets/scripts/capture-theme-screenshots.sh \
	--check \
	--output-dir /tmp/neotheme-theme-inputs
```
