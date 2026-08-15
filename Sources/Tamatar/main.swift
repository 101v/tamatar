import AppKit
import Darwin

/// When started from a terminal, relaunch detached so the shell is not blocked.
/// Use `--foreground` (e.g. during development) to keep the process attached.
private func detachFromTerminalIfNeeded() {
    if CommandLine.arguments.contains("--foreground") {
        return
    }
    guard isatty(STDIN_FILENO) != 0 else {
        return
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
    var args = Array(CommandLine.arguments.dropFirst())
    args.insert("--foreground", at: 0)
    process.arguments = args
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
        exit(0)
    } catch {
        // Fall through and run attached if relaunch fails.
    }
}

detachFromTerminalIfNeeded()

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

app.run()
