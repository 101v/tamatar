# Tamatar — Implementation Spec

A macOS menu-bar Pomodoro timer. Runs in the background (no Dock icon), shows a
menu-bar item, lets the user start a countdown timer, and pops a "Time is up"
window on screen when the timer reaches zero.

---

# FEATURE DELTA (current task): Ticking Sound + Mute

> This section is the spec for the CURRENT feature only. It is self-contained:
> the Coder implements exactly what is below. The rest of this file (after the
> `---` divider) is prior context describing the already-built app.

**Feature request:** Play a ticking sound each second while the timer is
running, and give the user a menu option to mute it.

## OPEN QUESTIONS (feature delta)

None blocking. Reasonable defaults chosen below; see DELTA ASSUMPTIONS. Proceed.

## DELTA ASSUMPTIONS (decisions made by the planner — do not re-litigate)

1. **Sound source = macOS system sound, no bundled audio asset.** Use
   `NSSound(named:)` with the built-in system sound named **`"Tink"`** (a short
   tick from `/System/Library/Sounds`). Rationale: avoids shipping a binary
   `.wav`/`.aiff` resource and the SPM `resources:`/`Bundle.module` plumbing an
   executable target would otherwise need. One short sound played per 1-second
   tick reads as "ticking." If a future continuous-loop clock sound is wanted,
   that requires a bundled asset — out of scope here.
2. **Where sound lives:** AppKit executable target `Tamatar` ONLY. `TamatarCore`
   stays pure (no AppKit, no audio) so it remains CLI-unit-testable. No changes
   to `PomodoroTimer.swift`.
3. **Driving the sound:** play one tick inside the existing `pomodoro.onTick`
   callback in `AppDelegate` (it already fires once per second only while
   running and is already dispatched to the main thread). Do NOT add a second
   timer.
4. **Mute is persistent.** Store the muted flag in `UserDefaults` under key
   `"com.tamatar.tickingMuted"` so the choice survives app restarts. Default =
   **not muted** (ticking on) on first launch.
5. **No new TamatarCore unit tests.** Audio + menu live in the AppKit layer,
   which is not CLI-testable (same boundary the prior spec set). Existing
   `PomodoroTimerTests` must continue to pass unchanged. Verification of the
   sound/mute is a manual smoke test (see Tester notes at end of delta).

## Files to modify / create (feature delta — exact paths)

```
CREATE  Sources/Tamatar/TickingSoundPlayer.swift
MODIFY  Sources/Tamatar/AppDelegate.swift
```

No changes to `Package.swift`, `TamatarCore`, `TimeUpWindow.swift`,
`main.swift`, or the tests.

### CREATE — `Sources/Tamatar/TickingSoundPlayer.swift`

A small, focused AppKit helper. **Follow the style of the existing
`Sources/Tamatar/TimeUpWindow.swift`** (a `final class` that wraps one AppKit
concern, private state, minimal public surface).

```swift
import AppKit

final class TickingSoundPlayer {
    /// Current mute state. Backed by UserDefaults.
    private(set) var isMuted: Bool

    /// Loads the persisted mute flag (default: not muted) and prepares the
    /// system sound. `soundName` defaults to "Tink".
    init(soundName: String = "Tink")

    /// Plays one tick. No-op if muted or if the sound could not be loaded.
    /// Must be called on the main thread. Restart the sound if it is still
    /// playing (stop-then-play) so rapid 1s ticks are not dropped.
    func playTick()

    /// Sets and persists the mute flag. When muting, stop any in-flight sound.
    func setMuted(_ muted: Bool)
}
```

Implementation notes:
- Hold a single `private let sound: NSSound?` from
  `NSSound(named: NSSound.Name(soundName))`. It may be `nil` — guard everywhere.
- Persistence: read in `init` via
  `UserDefaults.standard.bool(forKey: "com.tamatar.tickingMuted")` (absent key
  ⇒ `false` ⇒ not muted, which is the desired default). Write in `setMuted`.
- `playTick()`: `guard !isMuted, let sound else { return }`; if
  `sound.isPlaying { sound.stop() }`; then `sound.play()`.
- Keep the UserDefaults key as a single named constant in this file.

### MODIFY — `Sources/Tamatar/AppDelegate.swift`

1. **Add a stored property** next to the existing `timeUpWindow`:

```swift
private let tickingSound = TickingSoundPlayer()
```

2. **Play a tick on each second.** In `applicationDidFinishLaunching`, inside the
   existing `pomodoro.onTick` closure (which already does
   `DispatchQueue.main.async { ... }`), play a tick — but only when time
   remains, so the final tick to `0` (which simultaneously triggers the
   "Time is up" window) does NOT also tick:

```swift
pomodoro.onTick = { [weak self] remaining in
    DispatchQueue.main.async {
        self?.statusItem.button?.title = PomodoroTimer.formatted(remaining)
        if remaining > 0 {
            self?.tickingSound.playTick()
        }
    }
}
```

3. **Add the mute menu item.** In `buildMenu()`, insert a new section before the
   final `.separator()` / "Quit" block (follow the existing `NSMenuItem` +
   `item.target = self` pattern used for Start/Pause/etc.):

```swift
menu.addItem(.separator())

let muteItem = NSMenuItem(title: "Mute Ticking", action: #selector(toggleMute(_:)), keyEquivalent: "")
muteItem.target = self
muteItem.state = tickingSound.isMuted ? .on : .off
menu.addItem(muteItem)
```

   The checkmark (`.state`) reflects current mute state; initialize it from the
   persisted value so the menu is correct on launch.

4. **Add the action** in the `// MARK: - Actions` section, matching the existing
   private `@objc` action style:

```swift
@objc private func toggleMute(_ sender: NSMenuItem) {
    let newValue = !tickingSound.isMuted
    tickingSound.setMuted(newValue)
    sender.state = newValue ? .on : .off
}
```

## Edge cases the implementation MUST handle (feature delta)

- **Sound unavailable:** `NSSound(named:)` returns `nil` → `playTick()` is a
  silent no-op; app must not crash.
- **No tick at zero:** the tick to `remaining == 0` must NOT play a tick sound
  (guarded by `remaining > 0`); only the "Time is up" window fires there.
- **No ticking when not running:** ticking is driven solely by `onTick`, which
  only fires while `.running`. Pause/Reset/finish already stop the 1s timer, so
  no extra muting logic is needed on those paths.
- **Mute takes effect immediately:** toggling while running silences the very
  next tick (state is read per-tick in `playTick()`).
- **Overlapping ticks:** if a sound is still playing when the next tick arrives,
  stop-then-play so ticks aren't dropped or queued.
- **Persistence:** mute choice is read on launch and written on every toggle;
  default on first launch is unmuted.
- **Threading:** all `NSSound` calls happen on the main thread (via the existing
  `DispatchQueue.main.async` in `onTick`, and menu actions are already on main).

## Existing patterns to follow (feature delta)

- `Sources/Tamatar/TimeUpWindow.swift` — model `TickingSoundPlayer` on this:
  small `final class`, AppKit-only, private state, tiny public API.
- `Sources/Tamatar/AppDelegate.swift` — menu items are `NSMenuItem` with
  `item.target = self`; actions are `private @objc func`. Match that exactly.

## Tester notes (feature delta)

- `swift build` and `swift test` must still pass (no core changes; existing
  `PomodoroTimerTests` unaffected).
- Manual smoke test (requires macOS GUI session): `swift run Tamatar`, start a
  1-minute preset → hear a tick each second; toggle "Mute Ticking" (checkmark
  appears) → ticking stops immediately; untoggle → resumes; on the final second
  the "Time is up" window appears without a competing tick; quit and relaunch →
  mute state is remembered.

---

# PRIOR CONTEXT — already-built app (for reference only; NOT part of this task)

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
