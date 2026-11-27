#!/bin/bash
# session.sh close <summary> | open [term|session-id]
set -u
queue="$HOME/.claude/archive-queue"
archive="$HOME/.claude/archived-sessions"

# Only the actions about *this* conversation need its id, and it is not set outside Claude Code.
case "${1:-}" in
close)
  id="${CLAUDE_CODE_SESSION_ID:?}"
  mkdir -p "$queue"
  printf '%s\n' "${2:?summary required}" > "$queue/$id"
  bash "$(dirname "$0")/exit-later.sh" later
  echo "Closed: archived on exit, which comes once this turn ends."
  ;;
open)
  arg="${2:-}"
  if [ -z "$arg" ] && [ -f "$queue/${CLAUDE_CODE_SESSION_ID:?}" ]; then
    rm "$queue/$CLAUDE_CODE_SESSION_ID"
    bash "$(dirname "$0")/exit-later.sh" cancel
    echo "Reopened: this conversation stays open on exit."
  elif [[ "$arg" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
    src=$(ls "$archive"/*/"$arg.jsonl" 2>/dev/null | head -1)
    [ -n "$src" ] || { echo "Not archived: $arg"; exit 1; }
    project_dir=$(basename "$(dirname "$src")")
    dest="$HOME/.claude/projects/$project_dir"
    mkdir -p "$dest"
    mv "$src" "$dest/"
    [ -d "${src%.jsonl}" ] && mv "${src%.jsonl}" "$dest/"
    bash "$(dirname "$0")/../../bin/pending.sh" restore "$arg" "$(dirname "$src")"
    echo "Restored $arg ($project_dir): resume it with /resume or claude -r $arg."
  else
    # Candidates: date, project dir, session id, summary
    grep -i -- "$arg" "$archive/index.tsv" 2>/dev/null | tail -20
  fi
  ;;
*)
  echo "usage: session.sh close <summary> | open [term|session-id]" >&2
  exit 2
  ;;
esac
