import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Panel, Section } from '../types'

// One pane per section: with several panes open the engine draws them as tabs, in the order they were opened,
// and shows the one opened last. The open tasks come last so that theirs is the tab shown.
const PANES: readonly { id: string; section: Section; title: string; empty: string }[] = [
  { id: 'tasks-archived', section: 'archived', title: 'Arxivades', empty: 'Cap tasca arxivada.' },
  { id: 'tasks-closed', section: 'closed', title: 'Tancades', empty: 'Cap tasca tancada.' },
  { id: 'tasks', section: 'open', title: 'Obertes', empty: 'Cap tasca oberta.' },
]
const panel = atom(
  { plugin: 'tasks', key: 'panel' } as const,
  { open: [], closed: [], archived: [] },
  { shape: 'panel-2' },
)

// The sessions whose panel is shown are kept in the store, so a resumed session opens it again.
const shownKey = async ($: EngineInterface) => `shown:${await $.session.id()}`

// `pending.sh panel` prints one `<section>\t<head>\t<description>\t<note>` line per task.
const refresh = async ($: EngineInterface): Promise<Panel> => {
  const { stdout } = await $.process.run(
    [`${$.plugin.root}/skills/tasks/pending.sh`, 'panel'],
    { env: { CLAUDE_CODE_SESSION_ID: await $.session.id() } },
  )
  const next: Panel = { open: [], closed: [], archived: [] }
  for (const line of stdout.split('\n')) {
    const [section, head = '', description = '', note = ''] = line.split('\t')
    if (section === 'open' || section === 'closed' || section === 'archived') {
      next[section].push({ head, description, note })
    }
  }
  await update($, panel, () => next)

  return next
}

// Opens the panes, or retitles the open ones: each tab carries its section's count.
const show = async ($: EngineInterface) => {
  const tasks = await refresh($)
  for (const { id, section, title } of PANES) {
    await $.ui.open({ id, title: `${title} (${tasks[section].length})` })
  }
}

const hide = async ($: EngineInterface) => {
  await $.store.delete(await shownKey($))
  for (const { id } of PANES) await $.ui.close({ id })
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const started = await next(e)
    if (await $.store.get(await shownKey($))) await show($)

    return started
  })

  on('command.run', { command: 'tasks' }, async ($, e, next) => {
    const action = e.args.trim()
    if (action === 'show' || action === '') {
      await $.store.set(await shownKey($), true)
      await show($)

      return { text: 'Tasks panel shown.' }
    }
    if (action === 'hide') {
      await hide($)

      return { text: 'Tasks panel hidden.' }
    }

    return next(e)
  })

  // The person closing one tab closes the whole panel.
  on('ui.close', async ($, e, next) => {
    const closed = await next(e)
    if (e.origin.kind === 'person' && PANES.some(pane => pane.id === e.id)) await hide($)

    return closed
  })

  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const ran = await next(e)
    if (e.command.includes('pending.sh')) {
      if (await $.store.get(await shownKey($))) await show($)
      else await refresh($)
    }

    return ran
  })

  on('ui.render', { component: 'Pane' }, async ($, e, next) => {
    const pane = PANES.find(one => one.id === e.requestId)
    if (!pane) return next(e)
    const { Box, Text } = $.ui.resolve(e)
    const tasks = (await read($, panel))[pane.section]

    return (
      <Box flexDirection="column">
        {tasks.length === 0 && <Text dimColor>{pane.empty}</Text>}
        {tasks.map(task => (
          <Box flexDirection="column">
            <Text>{task.head}</Text>
            <Box paddingLeft={4} flexDirection="column">
              <Text wrap="wrap">{task.description}</Text>
              {task.note !== '' && (
                <Text wrap="wrap" dimColor>
                  {task.note}
                </Text>
              )}
            </Box>
          </Box>
        ))}
      </Box>
    )
  })
}
