import AppKit

final class TimeUpWindow {
    private var window: NSWindow?

    init() {}

    func show(message: String = "Time is up") {
        if window == nil {
            window = makeWindow(message: message)
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    private func makeWindow(message: String) -> NSWindow {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 160),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Tamatar"
        win.level = .floating
        win.isReleasedWhenClosed = false
        win.center()

        let contentView = NSView(frame: win.contentRect(forFrameRect: win.frame))

        let label = NSTextField(labelWithString: message)
        label.font = NSFont.systemFont(ofSize: 28, weight: .medium)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        let button = NSButton(title: "OK", target: self, action: #selector(dismiss))
        button.keyEquivalent = "\r"
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -20),

            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
        ])

        win.contentView = contentView
        return win
    }

    @objc private func dismiss() {
        window?.orderOut(nil)
    }
}
