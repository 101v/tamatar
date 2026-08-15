# Tamatar

A macOS menu-bar Pomodoro timer. *Tamatar* is the Hindi word for tomato (pomodoro).

Runs in the background (no Dock icon) with a 🍅 in the menu bar. Pick a duration, focus, and get an on-screen alert when time is up.

**Requirements:** macOS 13+ · [Homebrew](https://brew.sh) · Xcode 15+ (needed to build)

## Install

```bash
brew tap 101v/tamatar https://github.com/101v/tamatar
brew trust 101v/tamatar
brew install tamatar
```

Then start it:

```bash
tamatar
```

Or open **Tamatar** from Spotlight (`⌘ Space`). The app is linked into `~/Applications`.

> Third-party Homebrew taps must be trusted once with `brew trust` before install.

## Use

Click the 🍅 in the menu bar:

| Action | What it does |
| --- | --- |
| **25:00 / 15:00 / 05:00 / 01:00** | Set that duration and start immediately |
| **Start** | Begin countdown with the current duration |
| **Pause / Resume** | Pause or continue the running timer |
| **Reset** | Return to idle |
| **Quit** | Exit the app |

When the timer hits zero, a **Time is up** window appears. Click **OK** to dismiss it.

To quit from the terminal: `killall Tamatar`

## Upgrade

```bash
brew update
brew upgrade tamatar
```

## Install from source

```bash
git clone https://github.com/101v/tamatar.git
cd tamatar
./scripts/package-app.sh
open Tamatar.app
```

## Development

```bash
swift build
swift test
swift run Tamatar -- --foreground
```

Release steps for maintainers: [RELEASING.md](RELEASING.md).

## License

[MIT](LICENSE)
