---
name: tasks-add
description: "Add a task to this session's pending list: an open topic, for Claude or for the user."
argument-hint: "<id> <description>"
---

Run `${CLAUDE_SKILL_DIR}/../../bin/pending.sh` `add <owner> <id> "<description>"` and reply with its output, as is: one line. Owner: `claude` if Claude has to do it, `user` if the user has to (review, commit, decide, test). Missing id or description, or the script rejects the id → ask. Arguments: `$ARGUMENTS`
