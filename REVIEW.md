# Revisió pendent (esborra aquest fitxer quan l'hagis revisat)

Marketplace muntat sense supervisió la nit del 26/11/2026 i reduït al plugin `tasks` el 27/11/2026.

## Abans de publicar

- [ ] **Llicència.** No n'he triada cap. El validador avisa que el directori de plugins n'exigeix una
      (`LICENSE` a l'arrel o `license` a cada `plugin.json`).
- [ ] **Nom del marketplace**: `agilogy-claude-skills` (s'instal·la com a `tasks@agilogy-claude-skills`).
      Canvia'l a `.claude-plugin/marketplace.json` si en vols un altre.
- [ ] **Autor**: `Jordi Pradel` a `plugin.json`. Cap email.
- [ ] No he fet `git init` ni cap commit.

## Estructura

| Plugin | Contingut | Origen |
|---|---|---|
| `tasks` | tasks (+ mod del panell), session | claude-assets |

- `session` és dins de `tasks` perquè crida els scripts de `tasks` i entre plugins no hi ha camins fiables.
  El mod depèn del nom `tasks` (estat `tasks.panel`, ordre `tasks`). Les ordres passen a ser
  `/tasks:tasks` i `/tasks:session`.
- 27/11: `bye` i `wip` trets. `bye.sh` i `exit-after-turn.sh` passen a `session/` (`bye.sh` → `exit-later.sh`)
  perquè `/session close` els fa servir.

## Generalitzacions

- `~/.claude/skills/<x>/...` → `${CLAUDE_SKILL_DIR}/...` als SKILL.md i `$(dirname "$0")/../<x>/` entre scripts.
- **Hooks reconstruïts.** No he pogut llegir el teu `~/.claude/settings.json`, així que els he deduït dels
  comentaris dels scripts. Cal provar-los:
  - `tasks/hooks/lifecycle.json`: SessionStart `resume|compact` → `pending.sh hook`; SessionStart →
    `archive-session.sh sweep`; SessionEnd → `archive-session.sh`; Stop → `exit-after-turn.sh`.
  - ⚠️ Quan instal·lis el plugin, **treu els hooks equivalents del teu `settings.json`**, o s'executaran dos cops.
- **Mod de `tasks`**: només he canviat el camí a `skills/tasks/pending.sh`. Els hooks d'ordres van a
  `hooks/lifecycle.json`, declarat a `plugin.json`, i `hooks/hooks.json` es queda amb els mòduls.
  El validador ho reconeix tot. No l'he pogut provar en una sessió real.
- `archive-session.sh`: `ditto` (només macOS) → `cp -R`.
- També he tret les referències a ccx, al sandbox, a l'usuari `claude` i a `/Users/...`.

## Provat (26/11, amb el marketplace sencer)

- `claude plugin validate .`: ✔. `claude plugin marketplace add` + `install`: ✔.
- Proves de fum amb un HOME temporal: tasks (add/done/list/panel/hook), session close → archive → open,
  bye, wip (aquests dos ja no hi són).
- **No provat**: el mod en una sessió real, els hooks en una sessió real.
