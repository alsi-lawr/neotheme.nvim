#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
runtime_dir=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}

for test_file in "$root"/tests/spec/*.lua; do
	name=$(basename "$test_file" .lua)
	printf 'test: %s\n' "$name"
	NVIM_LOG_FILE="${TMPDIR:-/tmp}/neotheme-${name}.log" \
		XDG_RUNTIME_DIR="$runtime_dir" \
		nvim --headless --noplugin -u "$root/tests/minimal_init.lua" -i NONE -n -l "$test_file"
done
