---
name: tasks-review
description: "Review this session's pending list: add the open topics missing from it and close the resolved ones. Replies nothing."
---

Script: `${CLAUDE_SKILL_DIR}/../../bin/pending.sh`.

1. Look for open topics missing from the list:
   - in this conversation, only since the previous review (from the start if none):
     - owner `user`: questions Claude asked or offers it made, in any wording, that the user neither answered nor declined; things only the user can do that Claude asked for (review a merge request, approve a commit, merge, run a command, test by hand, provide data);
     - owner `claude`: user questions left unanswered; user requests done in part or not at all; anything that failed, was skipped, was denied or was left unverified, unless Claude dropped it on purpose and said so; problems Claude found and reported, neither fixed nor dismissed by the user; implemented work not yet reviewed against the request; anything started and not finished: a background agent or task still running, a plan halfway, a wait on CI or on someone, a temporary file, branch, worktree or setting to clean up;
     - either owner: anything the user or Claude postponed; the owner is whoever picks it up;
     - skip what the user dismissed, and trivia;
   - uncommitted changes in any repo/worktree touched in this conversation;
   - commits not pushed to their remote branch in those repos, the default branch included;
   - branches/worktrees worked on here that haven't landed on the repo's default branch, `main` or `master` — as the same commits, rebased, or squashed: with an open merge request, its merge task; with none, the `[/]` task of the work.
   The git checks always cover the current state, not just what changed since the previous review.
   Add each with `pending.sh add <owner> <id> "<description>"` and a new short id (`pending.sh list` shows the list).
2. Go through every open item (`[ ]` and `[/]`): if the conversation or the git state shows it resolved, `pending.sh done <id>`; if the user abandoned it, `pending.sh drop <id> "<reason>"`.
3. Reply nothing about the review, not even a summary: the user sees the list with `/tasks:tasks-show`. If the review is all the turn does, end it with no text.
