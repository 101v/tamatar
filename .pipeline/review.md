# Review — Ticking Sound + Mute Feature

**Run date:** 2026-06-02
**Reviewer:** final-stage (read-only)

## VERDICT: SHIP

---

## What was reviewed

- `.pipeline/spec.md` (FEATURE DELTA section)
- `.pipeline/changes.md`, `.pipeline/test-results.md`
- `git diff` of the two changed files
- `Sources/Tamatar/TickingSoundPlayer.swift` (new)
- `Sources/Tamatar/AppDelegate.swift` (modified)
- `Sources/TamatarCore/PomodoroTimer.swift` (read for `onTick`-at-zero semantics)

## Independent verification

| Check | Result |
|---|---|
| `swift build` | Build complete, exit 0, no warnings |
| `swift test` | 33/33 passed, 0 failures, exit 0 |

Matches the Tester's reported results.

## Spec conformance

Every DELTA ASSUMPTION and edge case is satisfied:

1. **Sound source** — `NSSound(named: "Tink")`, no bundled asset. ✔
2. **Scope** — only `Tamatar` target touched; `TamatarCore`, `Package.swift`,
   `TimeUpWindow.swift`, `main.swift`, and tests are untouched. ✔
3. **Driven by `onTick`** — no second timer added; tick plays inside the
   existing `onTick` closure on the main thread. ✔
4. **Persistence** — `UserDefaults` key `com.tamatar.tickingMuted`, read in
   `init`, written in `setMuted`; absent key → `false` (unmuted default). ✔
5. **No new core tests** — existing `PomodoroTimerTests` unchanged and green. ✔

Public surface of `TickingSoundPlayer` matches the spec signature exactly
(`isMuted` private(set), `init(soundName:)`, `playTick()`, `setMuted(_:)`).

## Correctness (the parts that matter beyond green tests)

- **No tick at zero — verified, not assumed.** `PomodoroTimer.tick()` fires
  `onTick(0)` on the final 1→0 step (line 57) *before* `onFinish` (line 60).
  The `if remaining > 0` guard in `AppDelegate` therefore genuinely suppresses
  the competing tick on the last second. The guard is meaningful and correct.
- **Nil-sound safety** — `guard !isMuted, let sound else { return }` in
  `playTick()`; `sound?.stop()` in `setMuted`. No force-unwraps. A stripped
  system that returns `nil` is a silent no-op, no crash.
- **Overlapping ticks** — stop-then-play (`if sound.isPlaying { sound.stop() }`)
  prevents queuing/stacking on slow decode, per spec.
- **Immediate mute** — `isMuted` is read per call in `playTick()`, so a toggle
  silences the very next tick.
- **Threading** — all `NSSound` calls reach the player from the main thread
  (via the existing `DispatchQueue.main.async` in `onTick`, and the menu action
  which is already on main). No data races.
- **Mute-when-muting stop** — `setMuted(true)` stops any in-flight sound so a
  tick already playing is cut, matching the spec.

## Notes (non-blocking, no action required)

- The new "Mute Ticking" item is placed in its own separator-bounded section
  between Reset and Quit — matches the spec snippet and the existing
  `NSMenuItem` + `target = self` + `@objc private` pattern.
- The AppKit audio/menu layer remains outside automated CLI coverage by design
  (same boundary as the prior spec). The manual smoke checklist in
  `test-results.md` is the correct verification path and is complete. Human
  sign-off should run that checklist on a GUI session before merge — in
  particular: audible tick each second, mute checkmark toggles + persists
  across relaunch, and no tick on the final second.

## Bottom line

Code matches the spec exactly, build and tests are green on an independent run,
and the one behavior that green tests do *not* cover (no tick at zero, nil/
threading/overlap safety) was traced through the source and holds. Ship it —
pending the manual GUI smoke checklist at human sign-off.
