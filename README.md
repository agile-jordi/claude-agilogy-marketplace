# claude-skills

A [Claude Code](https://code.claude.com) plugin marketplace. For now it holds one plugin, `tasks`: a
per-session pending list and closing and archiving conversations.

## Install

```bash
claude plugin marketplace add agilogy/claude-skills
claude plugin install tasks@agilogy-claude-skills
```

Inside a session, `/plugin marketplace add agilogy/claude-skills` and `/plugin` do the same.
Plugin skills are invoked with the plugin name as prefix, e.g. `/tasks:tasks`, `/tasks:session`.

## Plugins

| Plugin | What it gives you |
|---|---|
| `tasks` | `/tasks`: a per-session pending list with a side panel (a Claude Code mod); `/session`: recap, close and archive conversations so they leave `/resume`, reopen them. Hooks: restore the list on resume/compact, archive closed or empty sessions, exit after `/session close`. |

## Requirements

- `bash`, `git`, `jq` and `python3`.

The tasks panel titles are in Catalan; Claude still replies in the language you write in.

## Layout

```
.claude-plugin/marketplace.json   the catalog
plugins/<name>/.claude-plugin/plugin.json
plugins/<name>/skills/<skill>/SKILL.md (+ scripts)
plugins/<name>/hooks/*.json (+ scripts)
```

Validate after any change with `claude plugin validate .`
