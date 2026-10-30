#!/bin/bash
set -Eeu -o pipefail

# List unfinished work in the repositories directly under a root directory
# (default: $HOME) and in the chezmoi source directory, after fetching all remotes.
# Prints lines sorted by repository: <repository>\t<kind>\t<details>
#   fetch-failed  first line of the git error
#   uncommitted   staged=<n> unstaged=<n> untracked=<n>
#   ahead         <branch> <n>  (one line per branch)
#   behind        <branch> <n>  (one line per branch)
#   no-upstream   <branch>      (one line per branch; "(gone)" if the upstream was deleted)
#   stash         <n>
#   todo-file     <path> items=<n>  (tracked TODO.md; items are numbered list lines)
#   todo-comment  <path>:<line>:<text>  (one line per line containing TODO, FIXME, XXX or HACK, excluding mentions of TODO.md)
#   clean         no details; printed when none of the above apply

die() {
  echo "$*" >&2
  exit 1
}

if [[ $# -gt 1 ]]; then
  die "Usage: scan.sh [root_directory]"
fi

if ! ROOT=$(cd "${1:-$HOME}" && pwd -P); then
  die "Directory not found: ${1:-$HOME}"
fi
readonly ROOT

list_repositories() {
  local dir source
  for dir in "$ROOT"/*/; do
    if [[ -e "$dir.git" ]]; then
      (cd "$dir" && pwd -P)
    fi
  done
  if source=$(chezmoi source-path 2>/dev/null) && [[ -e "$source/.git" ]]; then
    (cd "$source" && pwd -P)
  fi
}

scan() {
  local repo=$1 found=false line

  local error
  if ! error=$(GIT_TERMINAL_PROMPT=0 git -C "$repo" fetch --all --prune --quiet 2>&1); then
    printf '%s\tfetch-failed\t%s\n' "$repo" "${error%%$'\n'*}"
    found=true
  fi

  local staged=0 unstaged=0 untracked=0
  while IFS= read -r line; do
    if [[ "${line:0:2}" == '??' ]]; then
      untracked=$((untracked + 1))
      continue
    fi
    if [[ "${line:0:1}" != ' ' ]]; then
      staged=$((staged + 1))
    fi
    if [[ "${line:1:1}" != ' ' ]]; then
      unstaged=$((unstaged + 1))
    fi
  done < <(git -C "$repo" status --porcelain)
  if [[ $((staged + unstaged + untracked)) -ne 0 ]]; then
    printf '%s\tuncommitted\tstaged=%d unstaged=%d untracked=%d\n' "$repo" "$staged" "$unstaged" "$untracked"
    found=true
  fi

  local branch upstream ahead behind
  while IFS=$'\t' read -r branch upstream; do
    if [[ -z "$upstream" ]]; then
      printf '%s\tno-upstream\t%s\n' "$repo" "$branch"
      found=true
      continue
    fi
    if ! git -C "$repo" rev-parse --verify --quiet "$upstream" >/dev/null; then
      printf '%s\tno-upstream\t%s (gone)\n' "$repo" "$branch"
      found=true
      continue
    fi
    read -r ahead behind < <(git -C "$repo" rev-list --left-right --count "refs/heads/$branch...$upstream")
    if [[ "$ahead" -ne 0 ]]; then
      printf '%s\tahead\t%s %d\n' "$repo" "$branch" "$ahead"
      found=true
    fi
    if [[ "$behind" -ne 0 ]]; then
      printf '%s\tbehind\t%s %d\n' "$repo" "$branch" "$behind"
      found=true
    fi
  done < <(git -C "$repo" for-each-ref --format=$'%(refname:lstrip=2)\t%(upstream)' refs/heads)

  local stashes
  stashes=$(git -C "$repo" stash list | wc -l)
  if [[ "$stashes" -ne 0 ]]; then
    printf '%s\tstash\t%d\n' "$repo" "$stashes"
    found=true
  fi

  local path items
  while IFS= read -r path; do
    if [[ ! -f "$repo/$path" ]]; then
      continue
    fi
    items=$(grep -cE '^[0-9]+\. ' "$repo/$path" || true)
    printf '%s\ttodo-file\t%s items=%d\n' "$repo" "$path" "$items"
    found=true
  done < <(git -C "$repo" ls-files -- ':(glob)**/TODO.md')

  while IFS= read -r line; do
    printf '%s\ttodo-comment\t%s\n' "$repo" "$line"
    found=true
  done < <(git -C "$repo" grep -nIP '\b(TODO|FIXME|XXX|HACK)\b(?!\.md)' -- . ':(exclude,glob)**/TODO.md' || true)

  if [[ "$found" == false ]]; then
    printf '%s\tclean\n' "$repo"
  fi
}

mapfile -t REPOSITORIES < <(list_repositories | sort -u)
readonly REPOSITORIES
if [[ ${#REPOSITORIES[@]} -eq 0 ]]; then
  die "No repositories found under $ROOT"
fi

for repo in "${REPOSITORIES[@]}"; do
  scan "$repo"
done
