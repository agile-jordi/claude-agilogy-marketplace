---
name: tasks
description: "This session's pending list: add, mark the work done but not yet in a merge request, tick (done), drop, move to a repo document, delegate to another session, archive the closed items, review (add missing open topics, close resolved ones), show or hide its side panel."
argument-hint: "[add <id> <description> | uncommitted <id> | done <id> | drop <id> [reason] | document <id> <doc> | delegate <id> [<session>] | archive | review | show | hide]"
---

Script: `${CLAUDE_SKILL_DIR}/pending.sh`. Except for `review`, reply with its output, as is: one line. Never print the list in the reply: the user sees it with `/tasks show`. Arguments: `$ARGUMENTS`

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
- `archive` → `pending.sh archive-closed` (prints the archived ids in one line).
- No argument, `show` | `hide` → the tasks panel's: typed as `/tasks`, `/tasks show` or `/tasks hide`, the mod (`hooks/register.tsx` of this plugin) answers before this skill runs. If you got here with one of them, the user did not type it or the mod is not loaded: say so and ask them to type it.
- `review` → look for open topics missing from the list:
  - in this conversation, only since the previous `review` (from the start if none):
    - owner `user`: questions Claude asked or offers it made, in any wording, that the user neither answered nor declined; things only the user can do that Claude asked for (review a merge request, approve a commit, merge, run a command, test by hand, provide data);
    - owner `claude`: user questions left unanswered; user requests done in part or not at all; anything that failed, was skipped, was denied or was left unverified, unless Claude dropped it on purpose and said so; problems Claude found and reported, neither fixed nor dismissed by the user; implemented work not yet reviewed against the request; anything started and not finished: a background agent or task still running, a plan halfway, a wait on CI or on someone, a temporary file, branch, worktree or setting to clean up;
    - either owner: anything the user or Claude postponed; the owner is whoever picks it up;
    - skip what the user dismissed, and trivia;
  - uncommitted changes in any repo/worktree touched in this conversation;
  - commits not pushed to their remote branch in those repos, the default branch included;
  - branches/worktrees worked on here that haven't landed on the repo's default branch, `main` or `master` — as the same commits, rebased, or squashed: with an open merge request, its merge task; with none, the `[/]` task of the work.
  The git checks always cover the current state, not just what changed since the previous `review`.
  Add each with `pending.sh add` and a new short id.
  Then go through every open item (`[ ]` and `[/]`): if the conversation or the git state shows it resolved, `pending.sh done <id>`; if the user abandoned it, `pending.sh drop <id> "<reason>"`.
  Reply nothing about the review, not even a summary: the user sees the list with `/tasks show`. If the review is all the turn does, end it with no text.
- Anything else → show the usage in the argument hint.
