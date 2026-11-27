#!/bin/bash
# exit-later.sh later: end this Claude Code session once the current turn is over, so its last reply is
#   already on screen (exit-after-turn.sh, a Stop hook, does it).
# exit-later.sh cancel: undo `later`.
set -u
markers="$HOME/.claude/exit-after-turn"
case "${1:-}" in
later)
  mkdir -p "$markers" && touch "$markers/${CLAUDE_CODE_SESSION_ID:?}"
  ;;
cancel)
  rm -f "$markers/${CLAUDE_CODE_SESSION_ID:?}"
  ;;
*)
  echo "usage: exit-later.sh later | cancel" >&2
  exit 2
  ;;
esac
