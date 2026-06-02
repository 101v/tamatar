# Tamatar — Implementation Spec

A macOS menu-bar Pomodoro timer. Runs in the background (no Dock icon), shows a
menu-bar item, lets the user start a countdown timer, and pops a "Time is up"
window on screen when the timer reaches zero.

## OPEN QUESTIONS

None blocking. Reasonable defaults chosen below; see ASSUMPTIONS. Proceed.

## ASSUMPTIONS (decisions made by the planner — do not re-litigate)

1. **Stack:** Swift + AppKit, built with Swift Package Manager (no `.xcodeproj`).
   Chosen so `swift build` / `swift test` run from the CLI, which the Coder and
   Tester need. Minimum platform: macOS 13.
2. **Architecture split:** All timer logic lives in a pure, UI-free library
   target `TamatarCore` so it is unit-testable from the CLI. The menu-bar UI is
   a thin AppKit executable `Tamatar` that wires `TamatarCore` to a real clock.
   The Tester targets `TamatarCore` only (AppKit UI is not CLI-testable).
3. **"Time is up" presentation:** a borderless, always-on-top `NSWindow`
   centered on the main screen with the text "Time is up" and an OK button.
   Activating it brings the app forward. (Not `NSAlert`, so it works reliably
   for an accessory/background app.)
4. **Background / no Dock icon:** set `NSApp.setActivationPolicy(.accessory)` at
   launch (programmatic equivalent of `LSUIElement`).
5. **Timer driver:** the executable uses a 1-second repeating `Foundation.Timer`
   that calls `PomodoroTimer.tick(by:)`. Tests call `tick(by:)` directly — no
   real waiting, no flaky time-based tests.
6. **Preset durations:** menu offers 25 min, 15 min, 5 min, and 1 min. Default
   duration 25 min. (Custom-duration entry is out of scope — not requested.)

This is a **greenfield** repo. There are no existing code patterns to follow;
create the structure exactly as specified below.

---

## Files to create (exact paths)

```
Package.swift
README.md
.gitignore
Sources/TamatarCore/PomodoroTimer.swift
Sources/Tamatar/main.swift
Sources/Tamatar/AppDelegate.swift
Sources/Tamatar/TimeUpWindow.swift
Tests/TamatarCoreTests/PomodoroTimerTests.swift
```

No files to modify (repo is empty apart from `.cursor/` and `.git/`).

---

## `Package.swift`

- `swift-tools-version: 5.9`
- Package name `Tamatar`, platforms `[.macOS(.v13)]`.
- Products:
  - `.executable(name: "Tamatar", targets: ["Tamatar"])`
- Targets:
  - `.target(name: "TamatarCore")` — no dependencies.
  - `.executableTarget(name: "Tamatar", dependencies: ["TamatarCore"])`
  - `.testTarget(name: "TamatarCoreTests", dependencies: ["TamatarCore"])`

---

## `Sources/TamatarCore/PomodoroTimer.swift`

Pure logic. No AppKit / no real timers. This is the unit-under-test.

```swift
import Foundation

public enum TimerState: Equatable {
    case idle       // configured, not started
    case running
    case paused
    case finished   // reached zero
}

public final class PomodoroTimer {
    public private(set) var state: TimerState
    public private(set) var duration: TimeInterval   // configured length, seconds
    public private(set) var remaining: TimeInterval  // seconds left, never < 0

    /// Called after every tick that changes `remaining` (while running).
    public var onTick: ((TimeInterval) -> Void)?
    /// Called exactly once when the timer reaches zero.
    public var onFinish: (() -> Void)?

    /// Default duration 25 minutes. Non-positive `duration` is clamped to 1s.
    public init(duration: TimeInterval = 25 * 60)

    /// Set a new duration. Allowed only when state is `.idle` or `.finished`.
    /// Ignored while `.running` or `.paused`. Non-positive is clamped to 1s.
    /// On success: resets `remaining = duration`, state becomes `.idle`.
    public func configure(duration: TimeInterval)

    /// Start a fresh countdown from `.idle` or `.finished`.
    /// Sets `remaining = duration`, state `.running`. No-op while running/paused.
    public func start()

    /// `.running` -> `.paused`. No-op otherwise.
    public func pause()

    /// `.paused` -> `.running`. No-op otherwise.
    public func resume()

    /// Any state -> `.idle`; `remaining = duration`. Cancels a finished state.
    public func reset()

    /// Advance the clock. No-op unless `.running`.
    /// Decrements `remaining` by `seconds` (default 1), clamped at 0.
    /// Fires `onTick(remaining)` when remaining changes.
    /// When remaining hits 0: state `.finished`, fires `onFinish()` exactly once.
    public func tick(by seconds: TimeInterval = 1)

    /// "MM:SS" for a non-negative seconds value. Minutes are not capped at 59
    /// (e.g. 90 min -> "90:00"). Negative input formats as "00:00".
    public static func formatted(_ seconds: TimeInterval) -> String
}
```

### Behavior / edge cases `PomodoroTimer` MUST handle

- `init` / `configure` with `duration <= 0` → clamp to `1`.
- `configure` while `.running` or `.paused` → ignored (no state/remaining change).
- `start` while already `.running` or `.paused` → no-op (does NOT restart).
- `pause` when not `.running` → no-op. `resume` when not `.paused` → no-op.
- `tick` when not `.running` → no-op (no callbacks).
- `tick` that would take `remaining` below 0 → clamp to 0.
- Reaching 0: set `.finished`, call `onFinish` **exactly once**; further `tick`
  calls are no-ops (state is `.finished`, not `.running`).
- After `.finished`, `start()` or `configure(...)` then `start()` runs again
  cleanly from full `duration`.
- `formatted`: `0 → "00:00"`, `5 → "00:05"`, `65 → "01:05"`, `1500 → "25:00"`,
  fractional seconds rounded down (floor) before formatting, negative → `"00:00"`.

---

## `Sources/Tamatar/main.swift`

Entry point (top-level executable code):

- Create `NSApplication.shared`.
- Set `app.setActivationPolicy(.accessory)` (no Dock icon, background agent).
- Instantiate `AppDelegate`, assign `app.delegate`, retain it.
- Call `app.run()`.

---

## `Sources/Tamatar/AppDelegate.swift`

`final class AppDelegate: NSObject, NSApplicationDelegate`.

Responsibilities:
- Own an `NSStatusItem` (variable length) created in
  `applicationDidFinishLaunching`. Button title shows a tomato emoji `🍅` when
  idle, and the live "MM:SS" countdown while running/paused (via
  `PomodoroTimer.formatted`).
- Own a `PomodoroTimer` (default 25 min).
- Build an `NSMenu` with items:
  - Section: preset durations "25:00", "15:00", "05:00", "01:00" — each selects
    a duration (calls `timer.configure` then `timer.start`).
  - "Start", "Pause", "Resume", "Reset".
  - Separator, then "Quit" (`NSApp.terminate`).
- Own a repeating 1-second `Foundation.Timer` (scheduled on the main run loop,
  common modes) that calls `pomodoro.tick()`. Start it when the countdown
  starts; invalidate/stop it on pause/reset/finish to avoid idle ticking.
- Wire `pomodoro.onTick` → update status-item title.
- Wire `pomodoro.onFinish` → stop the 1s timer, reset status title to `🍅`, and
  call into `TimeUpWindow` to show the alert (see below). Must run on the main
  thread.

Keep selectors/`@objc` actions minimal and private. No persistence, no
preferences window — not requested.

Edge cases:
- Selecting a preset while running should reconfigure and restart cleanly
  (reset first so `configure` is allowed, then `configure` + `start`).
- Showing the "Time is up" window must not block the run loop; reuse a single
  window instance if shown repeatedly.

---

## `Sources/Tamatar/TimeUpWindow.swift`

Encapsulates the on-screen "Time is up" alert.

```swift
import AppKit

final class TimeUpWindow {
    init()
    /// Brings the app forward and shows a centered, always-on-top window
    /// containing the message "Time is up" and an OK button that hides it.
    func show(message: String = "Time is up")
}
```

- Window: `NSWindow` with a titled, centered style; `level = .floating`;
  `isReleasedWhenClosed = false`. Centered via `center()`.
- Content: a label "Time is up" (large font) and an OK button that orders the
  window out (`orderOut`) / closes without releasing.
- Call `NSApp.activate(ignoringOtherApps: true)` before showing so it surfaces
  over other apps.

---

## `Tests/TamatarCoreTests/PomodoroTimerTests.swift`

Framework: **XCTest** (`import XCTest @testable import TamatarCore`). Run with
`swift test`. Cover at minimum (Tester may add more):

- Happy path: `start()` → state `.running`, `remaining == duration`; N `tick()`s
  decrement correctly; ticking to 0 sets `.finished` and fires `onFinish` once.
- `onFinish` fires exactly once even with extra ticks past zero.
- `tick` is a no-op when idle/paused/finished (remaining unchanged, no `onTick`).
- `pause` then `tick` does not decrement; `resume` then `tick` does.
- `configure` ignored while running/paused; honored when idle/finished.
- Non-positive duration clamps to 1s (failure/edge case).
- `reset` returns to `.idle` with `remaining == duration` from any state.
- `formatted`: the table in the edge-cases section above.

---

## Non-goals (do NOT build)

- Custom/arbitrary duration text entry, break/work cycle automation, sounds,
  notifications via `UserNotifications`, preferences persistence, launch-at-login,
  app icon/bundle packaging. None were requested.

## Build / run commands (for Coder & Tester)

- Build: `swift build`
- Test: `swift test`
- Run app: `swift run Tamatar`
