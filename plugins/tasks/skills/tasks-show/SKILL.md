---
name: tasks-show
description: "Show this session's pending list in a side panel."
disable-model-invocation: true
---

The mod of this plugin (`hooks/register.tsx`) answers `/tasks:tasks-show` before this skill runs. If you got here, the user did not type it or the mod is not loaded: say so and ask them to type it.
