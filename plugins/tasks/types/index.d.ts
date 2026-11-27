export type Task = { head: string; description: string; note: string }
export type Section = 'open' | 'closed' | 'archived'
export type Panel = Record<Section, Task[]>

declare module 'claude-code' {
  interface PluginState {
    tasks: { panel: Shaped<Panel> }
  }
}
