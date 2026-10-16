#!/bin/bash
set -Eeu -o pipefail

# Classify sibling repositories of a reference repository for rolling out one of its commits.
# Prints one line per target repository: <repository>\t<status>\t<details>
#   status:  apply | applied | exception | candidate
#   details: "; "-separated items such as apply=<paths>, differs=<paths>,
#            uncommitted=<paths>, staged-changes, other-changes=<paths>

die() {
  echo "$*" >&2
  exit 1
}

join_by_comma() {
  local IFS=,
  echo "$*"
}

if [[ $# -ne 2 ]]; then
  die "Usage: precheck.sh reference_repository commit"
fi

if ! REFERENCE=$(cd "$1" && pwd); then
  die "Directory not found: $1"
fi
readonly REFERENCE
readonly COMMIT=$2
if ! git -C "$REFERENCE" rev-parse --verify --quiet "$COMMIT^{commit}" >/dev/null; then
  die "Commit not found in $REFERENCE: $COMMIT"
fi
if ! git -C "$REFERENCE" rev-parse --verify --quiet "$COMMIT^" >/dev/null; then
  die "Commit has no parent: $COMMIT"
fi

# Changed files as parallel arrays; a missing side is an empty "mode blob" string
PATHS=()
OLD_ENTRIES=()
NEW_ENTRIES=()
ADDED_ONLY=true
readonly ZERO_MODE=000000
while IFS=$'\t' read -r meta path; do
  read -r old_mode new_mode old_blob new_blob status <<<"${meta#:}"
  PATHS+=("$path")
  if [[ "$old_mode" == "$ZERO_MODE" ]]; then
    OLD_ENTRIES+=("")
  else
    OLD_ENTRIES+=("$old_mode $old_blob")
  fi
  if [[ "$new_mode" == "$ZERO_MODE" ]]; then
    NEW_ENTRIES+=("")
  else
    NEW_ENTRIES+=("$new_mode $new_blob")
  fi
  if [[ "$status" != A ]]; then
    ADDED_ONLY=false
  fi
done < <(git -C "$REFERENCE" diff-tree -r --no-renames --no-commit-id "$COMMIT^" "$COMMIT")
readonly PATHS OLD_ENTRIES NEW_ENTRIES ADDED_ONLY

# Prints "mode blob" of a path in HEAD of a repository, or nothing if absent
head_entry() {
  local repo=$1 path=$2
  git -C "$repo" ls-tree HEAD -- "$path" | awk '{print $1 " " $3}'
}

is_target() {
  local repo=$1 i
  for i in "${!PATHS[@]}"; do
    if [[ "$ADDED_ONLY" == true ]]; then
      if [[ -n "$(git -C "$repo" ls-tree HEAD -- "$(dirname "${PATHS[i]}")")" ]]; then
        return 0
      fi
    elif [[ -n "${OLD_ENTRIES[i]}" && -n "$(head_entry "$repo" "${PATHS[i]}")" ]]; then
      return 0
    fi
  done
  return 1
}

porcelain_paths() {
  local repo=$1
  shift
  git -C "$repo" status --porcelain "$@" | cut -c4-
}

classify() {
  local repo=$1 name
  name=$(basename "$repo")

  if ! git -C "$repo" diff --cached --quiet; then
    printf '%s\texception\tstaged-changes\n' "$name"
    return
  fi

  local uncommitted
  mapfile -t uncommitted < <(porcelain_paths "$repo" -- "${PATHS[@]}")
  if [[ ${#uncommitted[@]} -ne 0 ]]; then
    printf '%s\texception\tuncommitted=%s\n' "$name" "$(join_by_comma "${uncommitted[@]}")"
    return
  fi

  local apply=() differs=() i entry
  for i in "${!PATHS[@]}"; do
    entry=$(head_entry "$repo" "${PATHS[i]}")
    if [[ "$entry" == "${NEW_ENTRIES[i]}" ]]; then
      continue
    elif [[ "$entry" == "${OLD_ENTRIES[i]}" ]]; then
      apply+=("${PATHS[i]}")
    elif [[ -n "$entry" ]]; then
      differs+=("${PATHS[i]}")
    fi
  done
  if [[ ${#differs[@]} -ne 0 ]]; then
    printf '%s\texception\tdiffers=%s\n' "$name" "$(join_by_comma "${differs[@]}")"
    return
  fi

  local status details=()
  if [[ ${#apply[@]} -eq 0 ]]; then
    status=applied
  else
    if [[ "$ADDED_ONLY" == true ]]; then
      status=candidate
    else
      status=apply
    fi
    details+=("apply=$(join_by_comma "${apply[@]}")")
  fi
  local other
  mapfile -t other < <(porcelain_paths "$repo")
  if [[ ${#other[@]} -ne 0 ]]; then
    details+=("other-changes=$(join_by_comma "${other[@]}")")
  fi
  local joined
  joined=$(printf '%s; ' "${details[@]}")
  printf '%s\t%s\t%s\n' "$name" "$status" "${joined%; }"
}

FOUND=false
for dir in "$(dirname "$REFERENCE")"/*/; do
  repo=${dir%/}
  if [[ "$repo" == "$REFERENCE" || ! -e "$repo/.git" ]]; then
    continue
  fi
  if is_target "$repo"; then
    classify "$repo"
    FOUND=true
  fi
done

if [[ "$FOUND" == false ]]; then
  die "No target repositories found for $COMMIT"
fi
