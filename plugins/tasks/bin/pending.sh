#!/bin/bash
# pending.sh list [all] | add <claude|user> <id> <description> | uncommitted <id> | done <id> | drop <id> [reason]
#            document <id> <doc> | delegate <id> <session> | archive-closed | panel
#            hook | review-due | archive <id> <dir> | restore <id> <dir>      (session hooks and scripts)
# Marks: [ ] pending, [/] work done but not yet in a merge request, [x] done, [-] won't do,
# [>] moved to a document or delegated to a session. [ ] and [/] are open: listed first, never archived.
# uncommitted stamps the item with ✔️ <date>; closing an item stamps it with 🗃️ <date>.
# archive-closed: moves the non-open items to the archived section and prints their ids.
# panel: what the tasks panel (the plugin's hooks/register.tsx) draws, a line per item:
# "<open|closed|archived><TAB><mark> <owner> <id><TAB><description><TAB><note>", the note being what follows the
# ➕ date but the ✔️ stamp (a drop's reason, a document or session, the 🗃️ date).
# hook: SessionStart hook (resume/compact), puts this session's non-archived list back into context.
# review-due: UserPromptSubmit hook, counts this session's prompts and, every $CLAUDE_TASKS_REVIEW_EVERY (default 5),
# tells Claude to run a review in that turn.
# archive: archives the closed items of a session's pending list and moves the list to <dir>/<id>.pending.md.
# restore: moves <dir>/<id>.pending.md back as that session's pending list.
set -u
pending_dir="$HOME/.claude/pending"
open_re='^- \[[ /]\] '
archived_header='## Archived'
list_file() { echo "$pending_dir/${CLAUDE_CODE_SESSION_ID:?}.md"; }
active_items() { sed "/^$archived_header\$/,\$d" "$1" 2>/dev/null | grep -- '^- \['; }
archived_items() { sed -n "/^$archived_header\$/,\$p" "$1" 2>/dev/null | grep -- '^- \['; }
# write_list <file> <active items> <archived items>
write_list() {
  {
    [ -n "$2" ] && printf '%s\n' "$2"
    [ -n "$2" ] && [ -n "$3" ] && echo
    [ -z "$3" ] || printf '%s\n\n%s\n' "$archived_header" "$3"
  } > "$1.tmp" && mv -- "$1.tmp" "$1"
}
# archive_closed <file>: moves the non-open items to the archived section and prints them.
archive_closed() {
  local closed archived
  closed=$(active_items "$1" | grep -v -- "$open_re")
  [ -n "$closed" ] || return 0
  archived=$(archived_items "$1")
  write_list "$1" "$(active_items "$1" | grep -- "$open_re")" "${archived:+$archived$'\n'}$closed"
  echo "$closed"
}
# show_active <file>: the non-archived items, open ones first, then a blank line and the closed ones.
show_active() {
  local items open closed
  items=$(active_items "$1") || return 1
  open=$(grep -- "$open_re" <<< "$items") closed=$(grep -v -- "$open_re" <<< "$items")
  [ -z "$open" ] || echo "$open"
  [ -z "$open" ] || [ -z "$closed" ] || echo
  [ -z "$closed" ] || echo "$closed"
}
# show_list <file> [all]: the non-archived items and, with all, the archived section.
show_list() {
  local active archived
  active=$(show_active "$1") archived=$(archived_items "$1")
  [ "${2:-}" = all ] || archived=
  [ -n "$active$archived" ] || { echo "No tasks."; return 0; }
  [ -z "$active" ] || echo "$active"
  [ -z "$active" ] || [ -z "$archived" ] || echo
  [ -z "$archived" ] || printf '%s\n\n%s\n' "$archived_header" "$archived"
}
# mark <id> <mark> <stamp> [note]: re-marks an open item in the active section, with the note before the stamp.
mark() {
  file=$(list_file) id="$1"
  n=$(active_items "$file" | grep -n -- "$open_re.* \`$id\` — " | head -1 | cut -d: -f1)
  [ -n "$n" ] || { echo "no open task with id: $id" >&2; exit 1; }
  active=$(active_items "$file" | awk -v n="$n" -v m="$2" -v note="${4:-}" -v stamp="$3 $(date +%F)" \
    'NR == n { sub("^- \\[[ /]\\]", "- [" m "]"); if (note != "") $0 = $0 " " note; print $0 " " stamp; next } 1')
  write_list "$file" "$active" "$(archived_items "$file")"
  active_items "$file" | sed -n "${n}p"
}

case "${1:-}" in
list) show_list "$(list_file)" "${2:-}" ;;
add)
  case "${2:-}" in claude) owner=🤖 ;; user) owner=👤 ;; *) echo "owner must be claude or user" >&2; exit 1 ;; esac
  id="${3:-}" desc="${4:-}"
  [[ "$id" =~ ^[^[:space:]\`]+$ ]] && [ -n "$desc" ] || { echo "id (no spaces) and description required" >&2; exit 1; }
  file=$(list_file)
  grep -q -- "\`$id\` — " "$file" 2>/dev/null && { echo "id already in the list: $id" >&2; exit 1; }
  mkdir -p "$pending_dir"
  line="- [ ] $owner \`$id\` — $desc ➕ $(date +%F)"
  active=$(active_items "$file")
  write_list "$file" "${active:+$active$'\n'}$line" "$(archived_items "$file")"
  echo "$line"
  ;;
uncommitted)
  active_items "$(list_file)" | grep -q -- "^- \[/\] .* \`${2:-}\` — " && { echo "already marked uncommitted: $2" >&2; exit 1; }
  mark "${2:-}" / '✔️'
  ;;
done) mark "${2:-}" x '🗃️' ;;
drop)
  reason="${*:3}"
  mark "${2:-}" - '🗃️' "${reason:+❌ $reason}"
  ;;
document)
  [ -n "${3:-}" ] || { echo "document required" >&2; exit 1; }
  mark "${2:-}" '>' '🗃️' "→ $3"
  ;;
delegate)
  [ -n "${3:-}" ] || { echo "session required" >&2; exit 1; }
  mark "${2:-}" '>' '🗃️' "→ session $3"
  ;;
archive-closed)
  file=$(list_file)
  ids=$(archive_closed "$file" | sed 's/^[^`]*\(`[^`]*`\) — .*/\1/' | paste -sd, - | sed 's/,/, /g')
  echo "${ids:+Archived: }${ids:-No closed tasks to archive.}"
  ;;
panel)
  file=$(list_file) tab=$'\t'
  # panel_rows <section>: turns the item lines on stdin into the section's rows.
  panel_rows() {
    sed "s/^- \(\[.\] [^ ]*\) \`\([^\`]*\)\` — \(.*\) ➕ [0-9-]*\( ✔️ [0-9-]*\)\{0,1\} \{0,1\}\(.*\)\$/$1$tab\1 \2$tab\3$tab\5/"
  }
  active_items "$file" | grep -- "$open_re" | panel_rows open
  active_items "$file" | grep -v -- "$open_re" | panel_rows closed
  archived_items "$file" | panel_rows archived
  ;;
hook)
  file="$pending_dir/$(jq -r .session_id).md"
  items=$(show_active "$file") || exit 0
  printf 'Pending list of this session (tasks plugin):\n\n%s\n' "$items"
  ;;
archive)
  file="$pending_dir/$2.md"
  rm -f -- "$pending_dir/$2.turns"
  [ -f "$file" ] || exit 0
  archive_closed "$file" > /dev/null
  if [ -s "$file" ]; then mv -- "$file" "$3/$2.pending.md"; else rm -f -- "$file"; fi
  ;;
review-due)
  id=$(jq -r .session_id)
  every=${CLAUDE_TASKS_REVIEW_EVERY:-5}
  [[ "$every" =~ ^[1-9][0-9]*$ ]] || every=5
  counter="$pending_dir/$id.turns"
  mkdir -p "$pending_dir"
  n=$(( $(cat "$counter" 2>/dev/null || echo 0) + 1 ))
  echo "$n" > "$counter"
  if [ $((n % every)) -eq 0 ]; then
    echo 'In this turn, also run `/tasks:tasks-review` (via the Skill tool, skill `tasks:tasks-review`). It replies nothing.'
  fi
  ;;
restore)
  [ -f "$3/$2.pending.md" ] || exit 0
  mkdir -p "$pending_dir"
  mv -- "$3/$2.pending.md" "$pending_dir/$2.md"
  ;;
*)
  sed -n '2,4s/^# \{0,1\}//p' "$0" >&2
  exit 1
  ;;
esac
