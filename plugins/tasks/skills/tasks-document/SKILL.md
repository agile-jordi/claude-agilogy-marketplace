---
name: tasks-document
description: "Move a task of this session's pending list to a repo document, such as the work plan."
argument-hint: "<id> <doc>"
---

Write the task into `<doc>` (a repo file, e.g. the work plan; in its existing task format), then run `${CLAUDE_SKILL_DIR}/../../bin/pending.sh` `document <id> <doc>` with `<doc>` as a repo-relative path, and reply with its output, as is: one line. Missing doc → ask. Arguments: `$ARGUMENTS`
