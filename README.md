# Cadence

A small, native macOS todo app with a **cascading focus timer**. Only the top
task counts down; finishing it (or sending it to the bottom) auto-starts the
next. A live `MM:SS` countdown lives in the menu bar, and a **Take a break**
button pauses everything.

Frosted-glass window, light + dark mode (with an in-app toggle), SF Pro, and a
card-grouped layout inspired by apps like Display Buddy. Narrow footprint —
about the size of the macOS Calculator.

Built with Swift Package Manager — **no Xcode required**, just the Swift
command line tools (macOS 14+).

## Build & run

```bash
./build.sh        # compiles + assembles Cadence.app
open Cadence.app
```

Optionally move `Cadence.app` to `/Applications`.

> **First launch:** the app is ad-hoc signed (built locally, not notarized). If
> macOS blocks it, right-click `Cadence.app` → **Open** → **Open**, just once.

## Use

- Type in the bottom field and press **Return** to add a task (default 20 min).
- The top task is **active**. Adjust its duration via the `20m` keycap, then hit
  **Start** — after that, finishing or demoting a task auto-starts the next one.
- **Take a break** pauses the active timer; **Resume** continues.
- Mark the active task done with the ✓ in its card (or in the menu-bar popover).
- At `0:00` a chime plays and the active task offers **Done**, **+5 min**, or
  **Move down**.
- Drag tasks in **Up Next** to reprioritize; right-click for more actions.
- Completed tasks collect in **Done** (most recent first) with a **Clear** button.
- The ☀/🌙 toggle in the header switches light/dark; by default it follows the
  system.

State is saved to `~/Library/Application Support/Cadence/todos.json`.

## Project layout

```
Sources/Cadence/
  CadenceApp.swift          # @main: window + MenuBarExtra
  Models/                   # TodoItem, time formatting
  Store/TodoStore.swift     # @Observable queue + cascading timer + persistence
  Theme/                    # adaptive Palette, Typography (SF Pro), components,
                            # frosted-glass window backing
  Views/                    # ActiveBlock, TodoRow, TodoList, MenuBar
```
