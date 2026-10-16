#!/bin/bash
set -Eeu -o pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: diff-files.sh <dir1> <dir2> <path>..." >&2
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

diff_file() {
  local file="$1"
  if [[ ! -f "$dir1/$file" ]]; then
    echo "Only in $dir2: $file"
    echo
  elif [[ ! -f "$dir2/$file" ]]; then
    echo "Only in $dir1: $file"
    echo
  else
    local output
    output=$(diff -u "$dir1/$file" "$dir2/$file" || true)
    if [[ -n "$output" ]]; then
      echo "$output"
      echo
    fi
  fi
}

list_files() {
  fd --base-directory "$1" --hidden --exclude .git --type f | sort
}

for path in "$@"; do
  if [[ -f "$dir1/$path" || -f "$dir2/$path" ]]; then
    diff_file "$path"
  elif [[ -d "$dir1/$path" || -d "$dir2/$path" ]]; then
    # Run list_files each time instead of caching in variables or temp files to keep it simple
    comm -12 <(list_files "$dir1/$path") <(list_files "$dir2/$path") \
      | while IFS= read -r file; do
        diff_file "$path/$file"
      done

    comm -23 <(list_files "$dir1/$path") <(list_files "$dir2/$path") \
      | sed "s|^|Only in $dir1: $path/|"

    comm -13 <(list_files "$dir1/$path") <(list_files "$dir2/$path") \
      | sed "s|^|Only in $dir2: $path/|"
  else
    echo "Error: $path not found in either directory" >&2
  fi
done
