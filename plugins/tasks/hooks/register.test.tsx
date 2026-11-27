import { expect, mock, test } from 'claude-code/testing'

const pane = (requestId: string) =>
  ({
    plugin: 'tasks',
    component: 'Pane',
    requestId,
    props: {
      title: requestId,
      isFocused: false,
      bodyColumns: 40,
      placement: 'dock',
      scroll: { offset: 0, bodyRows: 20 },
      view: {},
    },
  }) as const

test('/tasks show opens a titled pane per section, each listing its tasks', async ($, on) => {
  mock.store(on)
  const opened: string[] = []
  on('session.id', () => ({ value: 's1' }))
  on('process.run', () => ({
    value: {
      exitCode: 0,
      stdout: [
        'open\t[ ] 🤖 panel\tSide panel\t',
        'open\t[/] 👤 review\tReview it\t',
        'closed\t[-] 🤖 hook\tFix the hook\t❌ not needed 🗃️ 2026-11-11',
        '',
      ].join('\n'),
      stderr: '',
      isStdoutTruncated: false,
      isStderrTruncated: false,
    },
  }))
  on('ui.open', (_, e) => {
    opened.push(`${e.id}: ${e.title}`)

    return { value: { isPlaced: true } }
  })

  const ran = await $.command.run({
    command: 'tasks',
    args: 'show',
    origin: { kind: 'composer' },
    presentation: { isFullscreen: true, columns: 160 },
  })

  expect(ran.text).toBe('Tasks panel shown.')
  expect(opened).toEqual([
    'tasks-archived: Archived (0)',
    'tasks-closed: Closed (1)',
    'tasks: Open (2)',
  ])
  for (const surface of ['terminal', 'desktop'] as const) {
    const open = await $.ui.mount({ ...pane('tasks'), surface })
    expect((await open.find({ type: 'Text', text: /panel/ }))?.text).toBe('[ ] 🤖 panel')
    expect(await open.find({ type: 'Text', text: /Review it/ })).toBeDefined()
    await open.unmount()

    const closed = await $.ui.mount({ ...pane('tasks-closed'), surface })
    expect((await closed.find({ type: 'Text', text: /not needed/ }))?.text).toBe(
      '❌ not needed 🗃️ 2026-11-11',
    )
    await closed.unmount()

    const archived = await $.ui.mount({ ...pane('tasks-archived'), surface })
    expect((await archived.find({ type: 'Text' }))?.text).toBe('No archived tasks.')
    await archived.unmount()
  }
})

test('/tasks with no arguments opens the panel too', async ($, on) => {
  mock.store(on)
  const opened: string[] = []
  on('session.id', () => ({ value: 's1' }))
  on('process.run', () => ({
    value: { exitCode: 0, stdout: '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false },
  }))
  on('ui.open', (_, e) => {
    opened.push(e.id)

    return { value: { isPlaced: true } }
  })

  const ran = await $.command.run({
    command: 'tasks',
    args: '',
    origin: { kind: 'composer' },
    presentation: { isFullscreen: true, columns: 160 },
  })

  expect(ran.text).toBe('Tasks panel shown.')
  expect(opened).toEqual(['tasks-archived', 'tasks-closed', 'tasks'])
})
