#!/usr/bin/env sh
# Generate the checked-in simplified-palette SVG cards from any directory.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

exec node "$script_dir/generate-palette-cards.mjs" "$@"
