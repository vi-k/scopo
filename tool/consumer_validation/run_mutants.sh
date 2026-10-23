#!/bin/sh
set -eu
KIT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export TMPDIR="$KIT/.review-tmp"
mkdir -p "$TMPDIR"
exec python3 "$KIT/tools/run_mutants.py" "$@"
