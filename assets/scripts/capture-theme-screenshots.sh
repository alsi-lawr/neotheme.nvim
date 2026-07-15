#!/usr/bin/env sh
# Capture live screenshots using the user's regular Neovim configuration.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
invocation_directory=$(pwd -P)
helper="$script_dir/capture-regular-config.lua"

output_directory="$repository_root/assets"
capture_file="$repository_root/lua/neotheme/init.lua"
config_file=""
nvim_command="nvim"
alacritty_command="alacritty"
spectacle_command="spectacle"
qdbus_command="qdbus"
focus_script="$script_dir/focus-capture-window.js"
columns=148
lines=52
timeout=30
settle=1
refresh_lualine=true
check=false
requested_themes=""
preview_pid=""
ready_file=""
error_file=""

usage() {
	cat <<'EOF'
Usage: assets/scripts/capture-theme-screenshots.sh [options] [theme ...]

Capture live PNG previews for all current Gruber themes, or only the named
public theme(s). Neovim loads its normal configuration unless --config is set;
the selected theme is changed only inside the capture process.

Options:
  --config PATH             Use this Neovim init.lua instead of the normal config.
  --output-dir PATH         Write PNGs here (default: <checkout>/assets).
  --file PATH               Open this file in the capture (default: neotheme init.lua).
  --columns NUMBER          Alacritty width in columns (default: 148).
  --lines NUMBER            Alacritty height in lines (default: 52).
  --timeout NUMBER          Seconds to wait for Neovim to apply the theme (default: 30).
  --settle NUMBER           Extra seconds to wait before capture (default: 1).
  --nvim PATH               Neovim executable (default: nvim).
  --alacritty PATH          Alacritty executable (default: alacritty).
  --spectacle PATH          Spectacle executable (default: spectacle).
  --qdbus PATH              KDE qdbus executable used to focus the capture window.
  --no-lualine-refresh      Do not reapply an already-loaded Lualine runtime config.
  --check                   Verify that the requested PNG assets exist; do not capture.
  -h, --help                Show this help.

The supported public names are gruber-dark-muted, gruber-dark, gruber-darker,
gruber-light, gruber-lighter, and gruber-light-muted.
EOF
}

die() {
	printf '%s\n' "$*" >&2
	exit 1
}

absolute_path() {
	case "$1" in
		/*) printf '%s\n' "$1" ;;
		*) printf '%s/%s\n' "$invocation_directory" "$1" ;;
	esac
}

is_positive_integer() {
	case "$1" in
		'' | *[!0-9]*) return 1 ;;
		*) [ "$1" -gt 0 ] ;;
	esac
}

is_nonnegative_integer() {
	case "$1" in
		'' | *[!0-9]*) return 1 ;;
		*) return 0 ;;
	esac
}

validate_theme() {
	case "$1" in
		gruber-dark-muted | gruber-dark | gruber-darker | gruber-light | gruber-lighter | gruber-light-muted) ;;
		*) die "Unknown theme: $1" ;;
	esac
}

title_for() {
	case "$1" in
		gruber-dark-muted) printf '%s\n' 'Gruber Dark Muted' ;;
		gruber-dark) printf '%s\n' 'Gruber Dark' ;;
		gruber-darker) printf '%s\n' 'Gruber Darker' ;;
		gruber-light) printf '%s\n' 'Gruber Light' ;;
		gruber-lighter) printf '%s\n' 'Gruber Lighter' ;;
		gruber-light-muted) printf '%s\n' 'Gruber Light Muted' ;;
	esac
}

require_executable() {
	case "$1" in
		*/*) [ -x "$1" ] || die "Executable not found: $1" ;;
		*) command -v "$1" >/dev/null 2>&1 || die "Command not found: $1" ;;
	esac
}

stop_preview() {
	if [ -n "$preview_pid" ]; then
		kill "$preview_pid" 2>/dev/null || true
		wait "$preview_pid" 2>/dev/null || true
		preview_pid=""
	fi
}

cleanup() {
	stop_preview
	if [ -n "$ready_file" ]; then
		rm -f "$ready_file"
	fi
	if [ -n "$error_file" ]; then
		rm -f "$error_file"
	fi
}

trap cleanup EXIT
trap 'exit 1' HUP INT TERM

while [ "$#" -gt 0 ]; do
	case "$1" in
		--config)
			[ "$#" -ge 2 ] || die '--config requires a path'
			config_file=$(absolute_path "$2")
			shift 2
			;;
		--output-dir)
			[ "$#" -ge 2 ] || die '--output-dir requires a path'
			output_directory=$(absolute_path "$2")
			shift 2
			;;
		--file)
			[ "$#" -ge 2 ] || die '--file requires a path'
			capture_file=$(absolute_path "$2")
			shift 2
			;;
		--columns)
			[ "$#" -ge 2 ] || die '--columns requires a number'
			columns=$2
			shift 2
			;;
		--lines)
			[ "$#" -ge 2 ] || die '--lines requires a number'
			lines=$2
			shift 2
			;;
		--timeout)
			[ "$#" -ge 2 ] || die '--timeout requires a number'
			timeout=$2
			shift 2
			;;
		--settle)
			[ "$#" -ge 2 ] || die '--settle requires a number'
			settle=$2
			shift 2
			;;
		--nvim)
			[ "$#" -ge 2 ] || die '--nvim requires a path'
			nvim_command=$2
			shift 2
			;;
		--alacritty)
			[ "$#" -ge 2 ] || die '--alacritty requires a path'
			alacritty_command=$2
			shift 2
			;;
		--spectacle)
			[ "$#" -ge 2 ] || die '--spectacle requires a path'
			spectacle_command=$2
			shift 2
			;;
		--qdbus)
			[ "$#" -ge 2 ] || die '--qdbus requires a path'
			qdbus_command=$2
			shift 2
			;;
		--no-lualine-refresh)
			refresh_lualine=false
			shift
			;;
		--check)
			check=true
			shift
			;;
		-h | --help)
			usage
			exit 0
			;;
		--*)
			die "Unknown option: $1"
			;;
		*)
			validate_theme "$1"
			requested_themes="$requested_themes $1"
			shift
			;;
	esac
done

is_positive_integer "$columns" || die '--columns must be a positive integer'
is_positive_integer "$lines" || die '--lines must be a positive integer'
is_positive_integer "$timeout" || die '--timeout must be a positive integer'
is_nonnegative_integer "$settle" || die '--settle must be a non-negative integer'

if [ -z "$requested_themes" ]; then
	set -- gruber-dark-muted gruber-dark gruber-darker gruber-light gruber-lighter gruber-light-muted
else
	# Each value was validated above and public theme names do not contain spaces.
	set -- $requested_themes
fi

if [ "$check" = true ]; then
	missing=false
	for theme in "$@"; do
		if [ ! -s "$output_directory/$theme.png" ]; then
			printf 'Missing screenshot: %s\n' "$output_directory/$theme.png" >&2
			missing=true
		fi
	done

	if [ "$missing" = true ]; then
		exit 1
	fi

	printf 'Requested screenshots exist in %s.\n' "$output_directory"
	exit 0
fi

[ -f "$helper" ] || die "Capture helper not found: $helper"
[ -f "$focus_script" ] || die "Window-focus helper not found: $focus_script"
[ -f "$capture_file" ] || die "Capture file not found: $capture_file"
if [ -n "$config_file" ]; then
	[ -f "$config_file" ] || die "Neovim config not found: $config_file"
fi

require_executable "$nvim_command"
require_executable "$alacritty_command"
require_executable "$spectacle_command"
require_executable "$qdbus_command"
mkdir -p "$output_directory"

focus_capture_window() {
	focus_plugin="neotheme-capture-focus-$1"
	"$qdbus_command" org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$focus_plugin" \
		>/dev/null 2>&1 || true
	"$qdbus_command" org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$focus_script" "$focus_plugin" \
		>/dev/null || die "Could not load the KDE window-focus helper for $1"
	"$qdbus_command" org.kde.KWin /Scripting org.kde.kwin.Scripting.start \
		>/dev/null || die "Could not start the KDE window-focus helper for $1"
	sleep 1
	"$qdbus_command" org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$focus_plugin" \
		>/dev/null 2>&1 || true
}

capture_theme() {
	theme=$1
	title=$(title_for "$theme")
	output_file="$output_directory/$theme.png"
	ready_file=$(mktemp "${TMPDIR:-/tmp}/neotheme-capture-ready.XXXXXX")
	error_file="$ready_file.error"
	log_file=$(mktemp "${TMPDIR:-/tmp}/neotheme-capture-$theme.XXXXXX.log")
	rm -f "$ready_file" "$error_file"

	set -- "$alacritty_command" \
		--class neotheme-capture \
		--title "neotheme.nvim - $title" \
		--working-directory "$repository_root" \
		-o "window.dimensions.columns=$columns" \
		-o "window.dimensions.lines=$lines" \
		-o window.padding.x=0 \
		-o window.padding.y=0 \
		-e "$nvim_command"

	if [ -n "$config_file" ]; then
		set -- "$@" -u "$config_file"
	fi

	set -- "$@" \
		--cmd 'lua vim.loader.disable()' \
		--cmd 'lua dofile(vim.env.NEOTHEME_CAPTURE_HELPER)' \
		-i NONE \
		-n \
		-- "$capture_file"

	NEOTHEME_CAPTURE_ROOT="$repository_root" \
	NEOTHEME_CAPTURE_THEME="$theme" \
	NEOTHEME_CAPTURE_FILE="$capture_file" \
	NEOTHEME_CAPTURE_HELPER="$helper" \
	NEOTHEME_CAPTURE_READY_FILE="$ready_file" \
	NEOTHEME_CAPTURE_ERROR_FILE="$error_file" \
	NEOTHEME_CAPTURE_REFRESH_LUALINE="$refresh_lualine" \
	"$@" >"$log_file" 2>&1 &
	preview_pid=$!

	remaining=$timeout
	while [ ! -f "$ready_file" ]; do
		if [ -f "$error_file" ]; then
			error_message=$(head -n 1 "$error_file")
			die "Neovim could not apply $theme: $error_message; see $log_file"
		fi
		if ! kill -0 "$preview_pid" 2>/dev/null; then
			wait "$preview_pid" 2>/dev/null || true
			die "Neovim exited before applying $theme; see $log_file"
		fi
		if [ "$remaining" -eq 0 ]; then
			die "Timed out waiting for $theme; see $log_file"
		fi
		sleep 1
		remaining=$((remaining - 1))
	done

	sleep "$settle"
	focus_capture_window "$theme"
	"$spectacle_command" --activewindow --background --nonotify --output "$output_file"
	[ -s "$output_file" ] || die "Screenshot was not written for $theme"
	stop_preview
	rm -f "$ready_file" "$error_file" "$log_file"
	ready_file=""
	error_file=""
	printf 'Captured %s\n' "$output_file"
}

for theme in "$@"; do
	capture_theme "$theme"
done
