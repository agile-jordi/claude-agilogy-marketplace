---
name: session
description: "/session [verbose]: recap, and a silent /tasks review. /session close: check nothing is pending, archive the conversation (hidden from /resume), exit. /session close!: same, no check. /session open [term]: reopen one. Triggers: tanca/reobre la conversa."
---

# /session [verbose | close | close! | open]

Script: `${CLAUDE_SKILL_DIR}/session.sh`.

## (no argument) | verbose

1. Run `/tasks review` (via the Skill tool, skill `tasks`). It replies nothing.
2. Reply in the conversation's language with only the recap: what was done in this conversation, at most
   3 lines. With `verbose`, a full recap with no line limit.

## close | close!

Closes this conversation: it's archived, no longer shows in `/resume`, and the session exits.
With `close!`, skip steps 1–2.

1. Run `/tasks review` (via the Skill tool, skill `tasks`). It replies nothing.
2. `${CLAUDE_SKILL_DIR}/../tasks/pending.sh list` shows open items (`[ ]` or `[/]`) → `AskUserQuestion`, naming
   them: close anyway, or keep open.
3. Run `session.sh close "<one-line summary, conversation's language>"`.
4. Reply with only this box, in a code block, in the conversation's language, with a blank line above
   and below the box. Size the frame to the longest line; 📦 takes two columns. The session exits by
   itself once this reply is done: don't run anything after step 3.

   ```


      ╭────────────────────────────────────────────╮
      │                                            │
      │   📦 Conversa arxivada                     │
      │   <one-line summary from step 3>           │
      │                                            │
      ╰────────────────────────────────────────────╯


   ```

## open [term]

Reopens a closed conversation so it shows in `/resume` again.

- `session.sh open` → if this conversation was closed, reopens it. Otherwise it
  lists recent archived ones (date, project, id, summary).
- `session.sh open <term>` → lists archived ones matching the term. Several →
  `AskUserQuestion`.
- `session.sh open <session-id>` → restores that one.

Archived transcripts live in `~/.claude/archived-sessions/<project-dir>/<id>.jsonl`
if you need to grep their content.
