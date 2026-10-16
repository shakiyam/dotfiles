#!/bin/bash
set -Eeu -o pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: compare-structure.sh <dir1> <dir2> <path>..." >&2
  exit 1
fi

readonly dir1="$1"
readonly dir2="$2"
shift 2

if [[ ! -d "$dir1" ]]; then
  echo "Error: directory not found: $dir1" >&2
  exit 1
fi
if [[ ! -d "$dir2" ]]; then
  echo "Error: directory not found: $dir2" >&2
  exit 1
fi

list_entries() {
  if [[ -d "$1" ]]; then
    fd --base-directory "$1" --hidden --exclude .git --max-depth 1 | sort
  fi
}

for path in "$@"; do
  # Run list_entries each time instead of caching in variables or temp files to keep it simple
  echo "=== $path ==="
  echo "Only in $dir1:"
  comm -23 <(list_entries "$dir1/$path") <(list_entries "$dir2/$path")
  echo "Only in $dir2:"
  comm -13 <(list_entries "$dir1/$path") <(list_entries "$dir2/$path")
  echo "Common:"
  comm -12 <(list_entries "$dir1/$path") <(list_entries "$dir2/$path")
  echo
done
