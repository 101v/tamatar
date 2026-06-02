# Changes — Ticking Sound + Mute Feature

## Files changed

### CREATED: `Sources/Tamatar/TickingSoundPlayer.swift`
New AppKit helper class. Loads the macOS system sound `"Tink"` via
`NSSound(named:)` once at init. Exposes:
- `isMuted: Bool` — reads from `UserDefaults` key `"com.tamatar.tickingMuted"` at
  init (absent key → `false`, i.e. not muted by default).
- `playTick()` — plays one tick; stops any in-flight sound first to avoid
  dropped/queued ticks. Silent no-op when muted or sound is unavailable.
- `setMuted(_:)` — persists the new flag to `UserDefaults`; stops any in-flight
  sound when muting.

### MODIFIED: `Sources/Tamatar/AppDelegate.swift`
Three focused changes only:
1. **New stored property** `private let tickingSound = TickingSoundPlayer()` added
   alongside the existing `timeUpWindow` property.
2. **`onTick` closure** updated to call `tickingSound.playTick()` when
   `remaining > 0` (no tick on the final zero-second callback).
3. **`buildMenu()`** — a new "Mute Ticking" `NSMenuItem` added between the existing
   Reset section and Quit, using `#selector(toggleMute(_:))` with checkmark state
   initialised from the persisted `isMuted` value.
4. **`toggleMute(_:)`** action added in `// MARK: - Actions` — flips and persists
   the mute flag, updates the menu item checkmark immediately.

## Build / test status
- `swift build` — passes (Build complete).
- `swift test` — all 33 `PomodoroTimerTests` pass; 0 failures.
- No changes to `TamatarCore`, `Package.swift`, or any test file.

## What the Tester should focus on

**Automated:** run `swift test` — must still show 33/33 passing.

**Manual smoke test (requires macOS GUI session):**
1. `swift run Tamatar` — menu bar shows 🍅.
2. Select a preset (e.g. "01:00") → countdown starts; a short tick should be
   audible each second.
3. Open menu → "Mute Ticking" has no checkmark. Click it → checkmark appears;
   ticking stops immediately on the very next second.
4. Click "Mute Ticking" again → checkmark removed; ticking resumes.
5. Let timer reach zero → "Time is up" window appears; no tick sound on that
   final second.
6. Quit and relaunch → "Mute Ticking" checkmark state matches the last-set value
   (persistence via `UserDefaults`).
7. Start a timer, pause it → no ticking while paused; resume → ticking resumes.
8. Start a timer, reset it → no ticking after reset.

**Edge cases to verify:**
- No crash if `NSSound(named: "Tink")` somehow returns `nil` (handled silently).
- Rapid ticking: each second's tick replaces the previous (stop-then-play),
  no audio queuing.
