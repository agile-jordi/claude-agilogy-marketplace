---
name: tasks-delegate
description: "Hand a task of this session's pending list to another local Claude session."
argument-hint: "<id> [session]"
---

Arguments: `$ARGUMENTS`

1. `<session>` missing → run `${CLAUDE_SKILL_DIR}/../../bin/delegate-target.sh` and use the name it prints; exit 1 → ask.
2. One `SendMessage` to it, self-contained, in the user's language, saying:
   - rename yourself `<id>` (or ask the user to run `/rename <id>` there), and work in a new worktree and branch
     named `<id>` (`EnterWorktree`) in the repo concerned;
   - what the task is, with all the context it needs: links, files, branches, findings, figures, open questions;
   - you answer to the user, not to the session that sent this: start by introducing to the user what you will do,
     then ask any doubts before starting; commit, push or publish only when the user asks;
   - no need to report back to the sender.
3. Run `${CLAUDE_SKILL_DIR}/../../bin/pending.sh` `delegate <id> <session>` and reply with its output, as is: one line.
4. Do not follow the session up: no idle notice, no further messages.
