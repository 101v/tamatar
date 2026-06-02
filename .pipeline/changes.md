# Implementation Changes

## Files Created

### `Package.swift`
Swift Package Manager manifest. Declares the `Tamatar` package targeting macOS 13,
with three targets: `TamatarCore` (library), `Tamatar` (executable), and
`TamatarCoreTests` (test target).

### `README.md`
Project overview, build/run commands, and usage instructions for the menu-bar app.

### `.gitignore`
Ignores `.build/`, `.DS_Store`, and other Swift/Xcode artefacts.

### `Sources/TamatarCore/PomodoroTimer.swift`
Pure Swift timer logic — no AppKit, no real wall-clock timers. Exposes:
- `TimerState` enum: `.idle`, `.running`, `.paused`, `.finished`
- `PomodoroTimer` class with `start`, `pause`, `resume`, `reset`, `configure(duration:)`,
  `tick(by:)`, and `formatted(_:)` static helper.
- Callbacks `onTick` and `onFinish`.
- All edge-case clamping (duration ≤ 0 → 1s; remaining never below 0; `onFinish`
  fires exactly once; ticks are no-ops outside `.running`).

### `Sources/Tamatar/main.swift`
Entry point. Creates `NSApplication.shared`, sets activation policy to `.accessory`
(no Dock icon), wires up `AppDelegate`, and calls `app.run()`.

### `Sources/Tamatar/AppDelegate.swift`
`NSApplicationDelegate` that owns the menu-bar status item, `PomodoroTimer`, and
`TimeUpWindow`. Responsibilities:
- Shows 🍅 when idle/finished, live "MM:SS" countdown while running/paused.
- Builds `NSMenu` with preset durations (25 / 15 / 5 / 1 min), Start/Pause/Resume/Reset,
  and Quit.
- Manages a repeating 1-second `Foundation.Timer` (started/stopped around
  run/pause/reset/finish) that drives `pomodoro.tick()`.
- Wires `onTick` → update status title; `onFinish` → stop tick timer, reset title,
  show `TimeUpWindow`.

### `Sources/Tamatar/TimeUpWindow.swift`
Encapsulates a single reusable `NSWindow` (`.floating` level, `isReleasedWhenClosed = false`)
with a large "Time is up" label and an OK button. `show()` activates the app and
centers + orders the window front. OK button calls `orderOut` (hides without releasing).

### `Tests/TamatarCoreTests/PomodoroTimerTests.swift`
XCTest suite for `TamatarCore`. Covers all cases listed in the spec:
- Happy-path start / tick / finish
- `onFinish` fires exactly once with extra ticks
- `tick` no-ops when idle, paused, finished
- Pause / resume behaviour
- `configure` ignored while running/paused, honoured when idle/finished
- Non-positive duration clamped to 1s
- `reset` from any state
- Re-`start` after finished
- `start` while running/paused is no-op
- Large tick clamped at 0
- `formatted` table: 0, 5, 65, 1500, fractional, negative, 90-min

## Build Result
`swift build` — **Build complete** (no warnings, no errors).

## What the Tester Should Focus On

1. **Run `swift test`** — all `PomodoroTimerTests` should pass.
2. **`onFinish` exactly-once** — key contract; extra ticks after finish must not
   re-fire the callback.
3. **Tick clamping** — `tick(by: 100)` on a 5s timer must stop at 0 and fire finish.
4. **`configure` guard** — must be ignored while running and paused.
5. **`formatted`** — fractional seconds (floor), negative input, large minute values.
6. **Manual smoke-test** (optional, requires macOS): `swift run Tamatar` — confirm
   🍅 in menu bar, preset timers reconfigure cleanly mid-run, "Time is up" window
   appears and is dismissable.
