---
name: tasks-uncommitted
description: "Mark a task of this session's pending list as done but not yet in a merge request."
argument-hint: "<id>"
---

Run `${CLAUDE_SKILL_DIR}/../../bin/pending.sh` `uncommitted <id>` and reply with its output, as is: one line. The work is done but is not yet in a merge request: not committed, not pushed, or pushed with no request open. The item shows as `[/]` and stays open. Arguments: `$ARGUMENTS`
