#!/bin/bash
# SessionEnd hook: archive the ending session if `/session close` queued it, or if the user never
# prompted anything in it (only local commands, no reply from Claude).
# SessionStart hook (arg "sweep"): archive every session that is no longer running and is queued or unprompted
# (e.g. its terminal was closed without the SessionEnd hook running, or a transcript no process ever owned).
# Archiving moves the transcript (and its subagent folder) out of ~/.claude/projects so /resume no longer lists it,
# and its pending list next to it, closed items archived (see bin/pending.sh).
set -u
queue_dir="$HOME/.claude/archive-queue"
archive_dir="$HOME/.claude/archived-sessions"

archive() { # id transcript
  local id=$1 transcript=$2 queue="$queue_dir/$1"
  [ -f "$queue" ] && [ -f "$transcript" ] || return 0
  local project_dir dest archived
  project_dir=$(basename "$(dirname "$transcript")")
  dest="$archive_dir/$project_dir"
  archived="$dest/$id.jsonl"
  mkdir -p "$dest"
  if [ -f "$archived" ]; then
    # Already archived: this is what Claude Code wrote after that, so append it rather than overwrite
    cat -- "$transcript" >> "$archived" && rm -f -- "$transcript" || return 0
    [ -d "${transcript%.jsonl}" ] && cp -R "${transcript%.jsonl}/." "$dest/$id/" && rm -rf -- "${transcript%.jsonl}"
  else
    mv -- "$transcript" "$dest/" || return 0
    [ -d "${transcript%.jsonl}" ] && mv -- "${transcript%.jsonl}" "$dest/"
    printf '%s\t%s\t%s\t%s\n' "$(date +%F)" "$project_dir" "$id" "$(head -1 "$queue")" >> "$archive_dir/index.tsv"
  fi
  bash "$(dirname "$0")/../../bin/pending.sh" archive "$id" "$dest"
  rm -f "$queue"
}

prompted() { # transcript: the user wrote a prompt or Claude replied (local commands alone don't count)
  jq -n -f "$(dirname "$0")/../session/prompted.jq" "$1"
}

running() { # id: some process of that session is alive
  # Its registered pid first: ps shows another user's environment only to root
  local f pid procs
  for f in "$HOME"/.claude/sessions/*.json; do
    [ -f "$f" ] && [ "$(jq -r '.sessionId // empty' "$f")" = "$1" ] || continue
    pid=$(jq -r '.pid // empty' "$f")
    [ -n "$pid" ] && ps -p "$pid" >/dev/null && return 0
  done
  # Snapshot first: a grep in the same pipeline would match its own argv
  procs=$(ps eww -A -o command= 2>/dev/null)
  [[ "$procs" == *"CLAUDE_CODE_SESSION_ID=$1"* ]]
}

queue_if_unprompted() { # id transcript
  if [ ! -f "$queue_dir/$1" ] && [ "$(prompted "$2")" = false ]; then
    mkdir -p "$queue_dir"
    echo "(sense missatges)" > "$queue_dir/$1"
  fi
}

input=$(cat)
if [ "${1:-}" = sweep ]; then
  current=$(printf '%s' "$input" | jq -r '.session_id // empty')
  for transcript in "$HOME"/.claude/projects/*/*.jsonl; do
    [ -f "$transcript" ] || continue
    id=$(basename "$transcript" .jsonl)
    [ "$id" = "$current" ] && continue
    [ -f "$queue_dir/$id" ] || [ "$(prompted "$transcript")" = false ] || continue
    running "$id" && continue
    queue_if_unprompted "$id" "$transcript"
    archive "$id" "$transcript"
  done
else
  id=$(printf '%s' "$input" | jq -r '.session_id // empty')
  transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
  [ -n "$id" ] && [ -f "$transcript" ] && queue_if_unprompted "$id" "$transcript"
  archive "$id" "$transcript"
fi
exit 0
