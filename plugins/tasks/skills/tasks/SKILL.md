---
name: tasks
description: "This session's pending list: show it (all: with the archived), add, mark the work done but not yet in a merge request, tick (done), drop, move to a repo document, delegate to another session, archive the closed items, review for missing open topics, show or hide its side panel."
argument-hint: "[all | add <id> <description> | uncommitted <id> | done <id> | drop <id> [reason] | document <id> <doc> | delegate <id> [<session>] | archive | review | show | hide]"
---

Script: `${CLAUDE_SKILL_DIR}/pending.sh`. Reply with its output, as is, keeping its order and blank lines (open items — `[ ]` pending and `[/]` done but not yet in a merge request —, a blank line, closed items). Arguments: `$ARGUMENTS`

- No argument → `pending.sh list`.
- `all` → `pending.sh list all`.
- `add <id> <description>` → `pending.sh add <owner> <id> "<description>"`. Owner: `claude` if Claude has to do it, `user` if the user has to (review, commit, decide, test). Missing id or description, or the script rejects the id → ask.
- `uncommitted <id>` → `pending.sh uncommitted <id>`: the work is done but is not yet in a merge request: not committed, not pushed, or pushed with no request open. The item shows as `[/]` and stays open (listed with the pending ones, never archived).
- `done <id>` → `pending.sh done <id>`.
- A task whose work ends in a commit is done once a merge request holds it: as soon as you finish the work, mark it `uncommitted` (also when the user says it is done but the commit is pending), and tick it `done` when the request exists and the commit is pushed to its branch, not when the request is merged. In a repo that takes no merge requests, tick it once committed.
- Every open merge request of this session's work has a task, owner `user`, to merge it (`merge-<n>`: "merge <repo> !<n>"): add it when you create the request, tick it once merged.
- Never add a task to pull, fast-forward or otherwise sync the user's main checkout (e.g. after pushing to the default branch), not even in `review`: the main checkout is the user's. When CLAUDE.md allows pulling it to build it, do it on the spot, never as a task.
- When you find that an open task is already done (e.g. someone else did it), tick it without asking and tell the user, so they can correct you.
- `drop <id> [reason]` → `pending.sh drop <id> "<reason>"` (omit the reason if none was given).
- `document <id> <doc>` → write the task into `<doc>` (a repo file, e.g. the work plan; in its existing task format), then `pending.sh document <id> <doc>` with `<doc>` as a repo-relative path. Missing doc → ask.
- `delegate <id> [<session>]` → hand the task to another local Claude session:
  1. `<session>` missing → `${CLAUDE_SKILL_DIR}/delegate-target.sh` and use the name it prints; exit 1 → ask.
  2. One `SendMessage` to it, self-contained, in the user's language, saying:
     - rename yourself `<id>` (or ask the user to run `/rename <id>` there), and work in a new worktree and branch
       named `<id>` (`EnterWorktree`) in the repo concerned;
     - what the task is, with all the context it needs: links, files, branches, findings, figures, open questions;
     - you answer to the user, not to the session that sent this: start by introducing to the user what you will do,
       then ask any doubts before starting; commit, push or publish only when the user asks;
     - no need to report back to the sender.
  3. `pending.sh delegate <id> <session>`.
  4. Do not follow the session up: no idle notice, no further messages.
- `archive` → `pending.sh archive-closed` (prints the archived ids in one line, then the non-archived list).
- `show` | `hide` → the tasks panel's: typed as `/tasks show` or `/tasks hide`, the mod (`hooks/register.tsx` of this plugin) answers before this skill runs. If you got here with one of them, the user did not type it or the mod is not loaded: say so and ask them to type it.
- `review` → look for open topics missing from the list:
  - deferred tasks, unanswered questions, unfinished requests, pending decisions in this conversation, only since the previous `review` (from the start if none);
  - uncommitted changes in any repo/worktree touched in this conversation;
  - branches/worktrees worked on here that haven't landed on the repo's default branch, `main` or `master` — as the same commits, rebased, or squashed: with an open merge request, its merge task; with none, the `[/]` task of the work.
  The git checks always cover the current state, not just what changed since the previous `review`.
  Add each with `pending.sh add` and a new short id. Then `pending.sh list`, appending ` 🆕` to the new items in the reply.
- Anything else → show the usage in the argument hint.
