# Tamatar

A macOS menu-bar Pomodoro timer. *Tamatar* is the Hindi word for tomato (pomodoro).

Runs as a background app (no Dock icon) with a 🍅 icon in the macOS menu bar.
Select a preset duration, start the countdown, and get an on-screen alert when time is up.

## Requirements

- macOS 13+
- Swift 5.9+ (Xcode 15+ for Homebrew builds)

## Install

### Homebrew

```bash
brew tap 101v/tamatar https://github.com/101v/tamatar
brew trust 101v/tamatar
brew install tamatar
Tamatar
```

This installs `Tamatar.app`, links it into `~/Applications` (for Spotlight), and adds a `Tamatar` / `tamatar` command that launches the app without blocking your terminal.

For the latest unreleased commits: `brew install --HEAD tamatar`. Release steps are in [RELEASING.md](RELEASING.md).

### From source

```bash
git clone https://github.com/101v/tamatar.git
cd tamatar
./scripts/package-app.sh
open Tamatar.app
```

Or run the binary directly (detaches from the terminal unless you pass `--foreground`):

```bash
swift build -c release
.build/release/Tamatar
```

## Build & Run (development)

```bash
# Build
swift build

# Run tests (TamatarCore logic only — AppKit UI is not CLI-testable)
swift test

# Run attached to the terminal (useful while debugging)
swift run Tamatar -- --foreground
```

## Usage

Click the 🍅 icon in the menu bar:

- **Preset durations** — 25:00, 15:00, 05:00, 01:00 — configure and start immediately.
- **Start** — begin countdown with the current duration.
- **Pause / Resume** — pause or resume the running timer.
- **Reset** — return to idle.
- **Quit** — exit the app.

When the timer reaches zero a "Time is up" window appears on screen. Click **OK** to dismiss it.

## License

[MIT](LICENSE)
