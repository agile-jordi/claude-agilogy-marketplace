#!/usr/bin/env bash
# The compact git state of a branch: run from inside the repo as `git-state.sh <branch> [<worktree>]`
# (claude-sessions does), it prints the branch's state.
G=/usr/bin/grep
[ -x "$G" ] || G=grep

# Sets default (the default branch), base (that branch on the remote, when there is one) and forge.
find_base() {
  local url
  if url=$(git remote get-url origin 2>/dev/null); then
    default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
    [ -z "$default" ] && default=$(git rev-parse -q --verify origin/main >/dev/null && echo main || echo master)
    base=origin/$default
    case $url in *gitlab*) forge=gitlab ;; *github*) forge=github ;; *) forge=other ;; esac
  else
    default=$(git rev-parse -q --verify main >/dev/null && echo main || echo master)
    base=$default
    forge=none
  fi
}

has_remote() { [ "$forge" != none ] && git rev-parse -q --verify "refs/remotes/origin/$1" >/dev/null; }

landed() {
  local b=$1
  if git merge-base --is-ancestor "$b" "$base"; then echo merged
  elif ! git cherry "$base" "$b" | $G -q '^+'; then echo rebased
  elif [ -z "$(git merge-tree "$(git merge-base "$base" "$b")" "$base" "$b")" ]; then echo squashed
  else echo no; fi
}

# Starship-style state: ⚠conflicts !modified (staged or not) ?untracked, ⇡ own commits not on
# origin/<b>, ⇣ commits on origin/<b> missing locally (neither counts commits already on the
# default branch), ↑ commits not on the default branch, ∅ branch not on the remote, ✓ nothing.
state() {
  local b=$1 path=$2 s="" st c m u up down ahead
  if [ -n "$path" ]; then
    st=$(git -C "$path" status --porcelain)
    c=$(echo "$st" | $G -cE '^(DD|AU|UD|UA|DU|AA|UU) ')
    m=$(echo "$st" | $G -vE '^(DD|AU|UD|UA|DU|AA|UU|\?\?) ' | $G -c '^[MADRC ][MD ] ')
    u=$(echo "$st" | $G -c '^?? ')
    [ "$c" -gt 0 ] && s+="⚠$c"; [ "$m" -gt 0 ] && s+="!$m"; [ "$u" -gt 0 ] && s+="?$u"
  fi
  if has_remote "$b"; then
    up=$(git rev-list --count "$b" --not "origin/$b" "$base")
    down=$(git rev-list --count "origin/$b" --not "$b" "$base")
    [ "$up" -gt 0 ] && s+=" ⇡$up"; [ "$down" -gt 0 ] && s+="⇣$down"
  fi
  ahead=0
  [ "$(landed "$b")" = no ] && ahead=$(git rev-list --count "$base..$b")
  [ "$ahead" -gt 0 ] && s+=" ↑$ahead"
  [ "$forge" != none ] && ! has_remote "$b" && s+=" ∅"
  s=${s# }; echo "${s:-✓}"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -u
  find_base
  state "$1" "${2:-}"
fi
