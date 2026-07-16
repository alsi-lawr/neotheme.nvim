# Reproducing the theme-browser recording

The tape uses the current source in the sibling `../vhs` checkout, including its record
capture mode. Nix supplies `ttyd`; it does not supply the VHS executable.

From the neotheme.nvim repository root:

```sh
VHS_BIN="$(pwd)/.agent-workspace/neotheme-vhs/vhs"
mkdir -p "$(dirname "$VHS_BIN")"
(cd ../vhs && GOTOOLCHAIN=auto go build -o "$VHS_BIN" .)
nix shell nixpkgs#ttyd --command \
	"$VHS_BIN" --capture-mode=record docs/vhs/neotheme-browser.tape
```

This regenerates [`docs/assets/neotheme-browser.webp`](../assets/neotheme-browser.webp).
