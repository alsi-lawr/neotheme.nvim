#!/usr/bin/env sh
# Generate the two final documentation assets for each theme family.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
source_directory=""
composer_arguments=""

while [ "$#" -gt 0 ]; do
	case "$1" in
		-h | --help)
			cat <<'EOF'
Usage: assets/scripts/generate-theme-assets.sh [--source-dir DIR] [--check] [root|family ...]

Generate only the final static matrix and animated carousel for each target.
Without --source-dir, temporary palette cards and editor screenshots are
created in a disposable working directory and removed after composition.
EOF
			exit 0
			;;
		--source-dir)
			[ "$#" -ge 2 ] || { printf '%s\n' '--source-dir requires a path' >&2; exit 1; }
			source_directory=$2
			shift 2
			;;
		*)
			composer_arguments="$composer_arguments $1"
			shift
			;;
	esac
done

cleanup=false
if [ -z "$source_directory" ]; then
	mkdir -p "$repository_root/.agent-workspace"
	source_directory=$(mktemp -d "$repository_root/.agent-workspace/theme-inputs.XXXXXX")
	cleanup=true
	trap 'rm -rf "$source_directory"' EXIT HUP INT TERM
	"$script_dir/generate-palette-cards.sh" --output-dir "$source_directory"
	"$script_dir/capture-theme-screenshots.sh" --output-dir "$source_directory"
fi

# Targets and executable overrides are whitespace-free public names or paths.
# shellcheck disable=SC2086
node "$script_dir/compose-theme-assets.mjs" --source-dir "$source_directory" $composer_arguments

if [ "$cleanup" = true ]; then
	rm -rf "$source_directory"
	rmdir "$repository_root/.agent-workspace" 2>/dev/null || true
	trap - EXIT HUP INT TERM
fi
