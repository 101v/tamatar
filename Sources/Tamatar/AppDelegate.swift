import AppKit
import TamatarCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let pomodoro = PomodoroTimer()
    private var tickTimer: Timer?
    private let timeUpWindow = TimeUpWindow()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusTitle()

        pomodoro.onTick = { [weak self] remaining in
            DispatchQueue.main.async {
                self?.statusItem.button?.title = PomodoroTimer.formatted(remaining)
            }
        }

        pomodoro.onFinish = { [weak self] in
            DispatchQueue.main.async {
                self?.stopTickTimer()
                self?.updateStatusTitle()
                self?.timeUpWindow.show()
            }
        }

        let menu = buildMenu()
        statusItem.menu = menu
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let presetsHeader = NSMenuItem(title: "Start Timer", action: nil, keyEquivalent: "")
        presetsHeader.isEnabled = false
        menu.addItem(presetsHeader)

        for (label, seconds) in [("25:00", 25 * 60), ("15:00", 15 * 60), ("05:00", 5 * 60), ("01:00", 1 * 60)] {
            let item = NSMenuItem(title: label, action: #selector(selectPreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = TimeInterval(seconds)
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let startItem = NSMenuItem(title: "Start", action: #selector(startTimer), keyEquivalent: "")
        startItem.target = self
        menu.addItem(startItem)

        let pauseItem = NSMenuItem(title: "Pause", action: #selector(pauseTimer), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)

        let resumeItem = NSMenuItem(title: "Resume", action: #selector(resumeTimer), keyEquivalent: "")
        resumeItem.target = self
        menu.addItem(resumeItem)

        let resetItem = NSMenuItem(title: "Reset", action: #selector(resetTimer), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    @objc private func selectPreset(_ sender: NSMenuItem) {
        guard let duration = sender.representedObject as? TimeInterval else { return }
        pomodoro.reset()
        pomodoro.configure(duration: duration)
        pomodoro.start()
        startTickTimer()
        updateStatusTitle()
    }

    @objc private func startTimer() {
        guard pomodoro.state == .idle || pomodoro.state == .finished else { return }
        pomodoro.start()
        startTickTimer()
        updateStatusTitle()
    }

    @objc private func pauseTimer() {
        pomodoro.pause()
        stopTickTimer()
        updateStatusTitle()
    }

    @objc private func resumeTimer() {
        pomodoro.resume()
        startTickTimer()
        updateStatusTitle()
    }

    @objc private func resetTimer() {
        pomodoro.reset()
        stopTickTimer()
        updateStatusTitle()
    }

    // MARK: - Tick Timer

    private func startTickTimer() {
        stopTickTimer()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.pomodoro.tick()
        }
        RunLoop.main.add(tickTimer!, forMode: .common)
    }

    private func stopTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    // MARK: - Status Title

    private func updateStatusTitle() {
        switch pomodoro.state {
        case .idle, .finished:
            statusItem.button?.title = "🍅"
        case .running, .paused:
            statusItem.button?.title = PomodoroTimer.formatted(pomodoro.remaining)
        }
    }
}
