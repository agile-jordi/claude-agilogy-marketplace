#!/bin/bash
# Prints the name of the session to delegate a task to: the most recently started live, idle, interactive peer
# session where the user has typed nothing (no transcript entry with origin.kind "human"; /rename does not count).
# Exits 1, printing nothing, when there is none.
set -u
best_start=0 best_name=""
for f in "$HOME"/.claude/sessions/*.json; do
  IFS=$'\t' read -r pid sid name status kind start < <(jq -r '[.pid, .sessionId, .name, .status, .kind, .startedAt] | @tsv' "$f")
  [ "$sid" = "${CLAUDE_CODE_SESSION_ID:?}" ] && continue
  [ "$kind" = interactive ] && [ "$status" = idle ] || continue
  ps -p "$pid" >/dev/null || continue
  transcript=$(find -L "$HOME/.claude/projects" -maxdepth 2 -name "$sid.jsonl" -print -quit)
  if [ -n "$transcript" ] && jq -e 'select(.origin.kind == "human")' "$transcript" >/dev/null; then continue; fi
  [ "$start" -gt "$best_start" ] && best_start=$start best_name=$name
done
[ -n "$best_name" ] || exit 1
echo "$best_name"
