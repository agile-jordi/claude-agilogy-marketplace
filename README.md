# claude-agilogy-marketplace

A [Claude Code](https://code.claude.com) plugin marketplace.

## Install

```bash
claude plugin marketplace add agilogy/claude-agilogy-marketplace
claude plugin install tasks@claude-agilogy-marketplace
```

Inside a session, `/plugin marketplace add agilogy/claude-agilogy-marketplace` and `/plugin` do the same.
Plugin skills are invoked with the plugin name as prefix, e.g. `/tasks:tasks-show`, `/tasks:session`.

## Plugins

| Plugin | What it gives you |
|---|---|
| [tasks](plugins/tasks/README.md) | A pending list per conversation, kept by Claude and shown in a side panel; `/session` to close and archive conversations; `claude-sessions` to list and resume them from the terminal. |

## Layout

```
.claude-plugin/marketplace.json   the catalog
plugins/<name>/.claude-plugin/plugin.json
plugins/<name>/README.md          its documentation
plugins/<name>/skills/<skill>/SKILL.md (+ scripts)
plugins/<name>/hooks/*.json (+ scripts)
```

Validate after any change with `claude plugin validate .`

## License

[MIT](LICENSE), © Agilogy.
