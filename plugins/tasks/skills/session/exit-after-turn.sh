#!/bin/bash
# Stop hook: ends the session once the turn is over if `exit-later.sh later` asked for it, so its last reply
# is already on screen. SIGTERM to its process, the nearest `claude` ancestor (SessionEnd hooks still run).
set -u
id=$(jq -r '.session_id // empty')
marker="$HOME/.claude/exit-after-turn/$id"
[ -n "$id" ] && [ -f "$marker" ] || exit 0
rm -f "$marker"
pid=$$
while [ "$pid" -gt 1 ]; do
  pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
  [ "$(basename "$(ps -o comm= -p "$pid")")" = claude ] && break
done
[ "$pid" -gt 1 ] || { echo "No claude process among this hook's ancestors" >&2; exit 1; }
kill -TERM "$pid"
