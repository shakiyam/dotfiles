#!/bin/bash
set -Eeu -o pipefail

# Watch the live Hunk session of a repository: clear all notes after each commit,
# and wait until the user adds notes, then print the new ones.
# Usage: watch-notes.sh <repository>
# Prints one line per new note: <file>:<line>: <body>
# Notes already reported by an earlier wait count as new only once, so notes added
# between two waits are reported by the next one; the first wait ignores existing notes.
# A change of HEAD, also one made between two waits, counts as a commit; clearing does not end the watch.
# Exits 0 after printing new notes, 1 when the session is gone or a required command is missing,
# and 0 with a message when another wait for the same repository is already running.
# WAIT_NOTES_INTERVAL sets the polling interval in seconds (default 2).

die() {
  echo "$*" >&2
  exit 1
}

head_commit() {
  git -C "$REPOSITORY" rev-parse --verify --quiet HEAD || true
}

list_notes() {
  hunk session comment list --repo "$REPOSITORY" --type user --json \
    | jq -c '[.comments[] | {noteId, filePath, line: (.newRange // .oldRange)[0], body}]'
}

if [[ $# -ne 1 ]]; then
  die "Usage: watch-notes.sh repository"
fi
for COMMAND in git hunk jq flock; do
  if ! command -v "$COMMAND" >/dev/null; then
    die "Command not found: $COMMAND"
  fi
done
readonly REPOSITORY=$1
readonly INTERVAL=${WAIT_NOTES_INTERVAL:-2}

KEY=$(printf '%s' "$REPOSITORY" | cksum | cut -d ' ' -f 1)
readonly STATE_PREFIX="${XDG_RUNTIME_DIR:-/tmp}/hunk-watch-notes-$KEY"
readonly SEEN_FILE="$STATE_PREFIX.seen"
readonly HEAD_FILE="$STATE_PREFIX.head"
exec {LOCK_FD}>"$STATE_PREFIX.lock"
if ! flock -n "$LOCK_FD"; then
  echo "Already waiting for notes in $REPOSITORY"
  exit 0
fi

if [[ ! -e $SEEN_FILE ]]; then
  if ! INITIAL=$(list_notes); then
    die "No live Hunk session for $REPOSITORY"
  fi
  jq -c 'map(.noteId)' <<<"$INITIAL" >"$SEEN_FILE"
fi
SEEN_IDS=$(<"$SEEN_FILE")
readonly SEEN_IDS

if [[ ! -e $HEAD_FILE ]]; then
  head_commit >"$HEAD_FILE"
fi
LAST_HEAD=$(<"$HEAD_FILE")
while true; do
  HEAD=$(head_commit)
  if [[ $HEAD != "$LAST_HEAD" ]]; then
    if ! hunk session comment clear --repo "$REPOSITORY" --all --yes >/dev/null; then
      die "Hunk session ended for $REPOSITORY"
    fi
    LAST_HEAD=$HEAD
    echo "$HEAD" >"$HEAD_FILE"
  fi
  if ! CURRENT=$(list_notes); then
    die "Hunk session ended for $REPOSITORY"
  fi
  NEW=$(jq -c --argjson seen "$SEEN_IDS" 'map(select(.noteId as $id | $seen | index($id) | not))' <<<"$CURRENT")
  if [[ $NEW != '[]' ]]; then
    jq -c --argjson seen "$SEEN_IDS" '$seen + map(.noteId)' <<<"$NEW" >"$SEEN_FILE"
    jq -r '.[] | "\(.filePath):\(.line): \(.body)"' <<<"$NEW"
    exit 0
  fi
  sleep "$INTERVAL"
done
