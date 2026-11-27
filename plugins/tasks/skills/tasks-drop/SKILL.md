---
name: tasks-drop
description: "Drop a task of this session's pending list: it won't be done."
argument-hint: "<id> [reason]"
---

Run `${CLAUDE_SKILL_DIR}/../../bin/pending.sh` `drop <id> "<reason>"` (omit the reason if none was given) and reply with its output, as is: one line. Arguments: `$ARGUMENTS`
