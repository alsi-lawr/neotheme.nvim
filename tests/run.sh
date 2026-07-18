#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
runtime_dir=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}

for test_file in "$root"/tests/spec/*.lua; do
	name=$(basename "$test_file" .lua)
	printf 'test: %s\n' "$name"
	state_home=$(mktemp -d "${TMPDIR:-/tmp}/neotheme-state-${name}.XXXXXX")
	trap 'rm -rf "$state_home"' EXIT HUP INT TERM
	NVIM_LOG_FILE="${TMPDIR:-/tmp}/neotheme-${name}.log" \
		XDG_RUNTIME_DIR="$runtime_dir" \
		XDG_STATE_HOME="$state_home" \
		nvim --headless --noplugin -u "$root/tests/minimal_init.lua" -i NONE -n -l "$test_file"
	rm -rf "$state_home"
	trap - EXIT HUP INT TERM
done
