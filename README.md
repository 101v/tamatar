# Tamatar

A macOS menu-bar Pomodoro timer. *Tamatar* is the Hindi word for tomato (pomodoro).

Runs as a background app (no Dock icon) with a 🍅 icon in the macOS menu bar.
Select a preset duration, start the countdown, and get an on-screen alert when time is up.

## Requirements

- macOS 13+
- Swift 5.9+

## Build & Run

```bash
# Build
swift build

# Run tests (TamatarCore logic only — AppKit UI is not CLI-testable)
swift test

# Run the app
swift run Tamatar
```

## Usage

Click the 🍅 icon in the menu bar:

- **Preset durations** — 25:00, 15:00, 05:00, 01:00 — configure and start immediately.
- **Start** — begin countdown with the current duration.
- **Pause / Resume** — pause or resume the running timer.
- **Reset** — return to idle.
- **Quit** — exit the app.

When the timer reaches zero a "Time is up" window appears on screen. Click **OK** to dismiss it.
