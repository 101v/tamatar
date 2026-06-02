import Foundation

public enum TimerState: Equatable {
    case idle
    case running
    case paused
    case finished
}

public final class PomodoroTimer {
    public private(set) var state: TimerState
    public private(set) var duration: TimeInterval
    public private(set) var remaining: TimeInterval

    public var onTick: ((TimeInterval) -> Void)?
    public var onFinish: (() -> Void)?

    public init(duration: TimeInterval = 25 * 60) {
        let clamped = max(duration, 1)
        self.duration = clamped
        self.remaining = clamped
        self.state = .idle
    }

    public func configure(duration: TimeInterval) {
        guard state == .idle || state == .finished else { return }
        let clamped = max(duration, 1)
        self.duration = clamped
        self.remaining = clamped
        self.state = .idle
    }

    public func start() {
        guard state == .idle || state == .finished else { return }
        remaining = duration
        state = .running
    }

    public func pause() {
        guard state == .running else { return }
        state = .paused
    }

    public func resume() {
        guard state == .paused else { return }
        state = .running
    }

    public func reset() {
        state = .idle
        remaining = duration
    }

    public func tick(by seconds: TimeInterval = 1) {
        guard state == .running else { return }
        remaining = max(remaining - seconds, 0)
        onTick?(remaining)
        if remaining == 0 {
            state = .finished
            onFinish?()
        }
    }

    public static func formatted(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "00:00" }
        let total = Int(seconds)
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
