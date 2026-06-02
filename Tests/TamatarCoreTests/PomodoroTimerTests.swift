import XCTest
@testable import TamatarCore

final class PomodoroTimerTests: XCTestCase {

    // MARK: - Happy path

    func testStartSetsRunningWithFullDuration() {
        let timer = PomodoroTimer(duration: 10)
        timer.start()
        XCTAssertEqual(timer.state, .running)
        XCTAssertEqual(timer.remaining, 10)
    }

    func testTicksDecrementRemaining() {
        let timer = PomodoroTimer(duration: 5)
        timer.start()
        timer.tick()
        XCTAssertEqual(timer.remaining, 4)
        timer.tick()
        XCTAssertEqual(timer.remaining, 3)
    }

    func testTickingToZeroSetsFinishedAndFiresOnFinish() {
        let timer = PomodoroTimer(duration: 2)
        var finishCount = 0
        timer.onFinish = { finishCount += 1 }
        timer.start()
        timer.tick()
        timer.tick()
        XCTAssertEqual(timer.state, .finished)
        XCTAssertEqual(timer.remaining, 0)
        XCTAssertEqual(finishCount, 1)
    }

    // MARK: - onFinish fires exactly once

    func testOnFinishFiresExactlyOnceWithExtraTicks() {
        let timer = PomodoroTimer(duration: 1)
        var finishCount = 0
        timer.onFinish = { finishCount += 1 }
        timer.start()
        timer.tick()  // reaches 0
        timer.tick()  // no-op: finished
        timer.tick()  // no-op: finished
        XCTAssertEqual(finishCount, 1)
    }

    // MARK: - No-ops when not running

    func testTickIsNoOpWhenIdle() {
        let timer = PomodoroTimer(duration: 10)
        var tickCalled = false
        timer.onTick = { _ in tickCalled = true }
        timer.tick()
        XCTAssertEqual(timer.remaining, 10)
        XCTAssertFalse(tickCalled)
    }

    func testTickIsNoOpWhenPaused() {
        let timer = PomodoroTimer(duration: 10)
        var tickCalled = false
        timer.onTick = { _ in tickCalled = true }
        timer.start()
        timer.pause()
        timer.tick()
        XCTAssertEqual(timer.remaining, 10)
        XCTAssertFalse(tickCalled)
    }

    func testTickIsNoOpWhenFinished() {
        let timer = PomodoroTimer(duration: 1)
        timer.start()
        timer.tick()
        XCTAssertEqual(timer.state, .finished)
        var tickCalled = false
        timer.onTick = { _ in tickCalled = true }
        timer.tick()
        XCTAssertFalse(tickCalled)
    }

    // MARK: - Pause / Resume

    func testPauseThenTickDoesNotDecrement() {
        let timer = PomodoroTimer(duration: 10)
        timer.start()
        timer.pause()
        timer.tick()
        XCTAssertEqual(timer.remaining, 10)
    }

    func testResumeThenTickDecrements() {
        let timer = PomodoroTimer(duration: 10)
        timer.start()
        timer.pause()
        timer.resume()
        timer.tick()
        XCTAssertEqual(timer.remaining, 9)
    }

    func testPauseWhenNotRunningIsNoOp() {
        let timer = PomodoroTimer(duration: 10)
        timer.pause()
        XCTAssertEqual(timer.state, .idle)
    }

    func testResumeWhenNotPausedIsNoOp() {
        let timer = PomodoroTimer(duration: 10)
        timer.start()
        timer.resume()
        XCTAssertEqual(timer.state, .running)
    }

    // MARK: - Configure

    func testConfigureIgnoredWhileRunning() {
        let timer = PomodoroTimer(duration: 10)
        timer.start()
        timer.configure(duration: 99)
        XCTAssertEqual(timer.duration, 10)
        XCTAssertEqual(timer.remaining, 10)
    }

    func testConfigureIgnoredWhilePaused() {
        let timer = PomodoroTimer(duration: 10)
        timer.start()
        timer.pause()
        timer.configure(duration: 99)
        XCTAssertEqual(timer.duration, 10)
    }

    func testConfigureHonoredWhenIdle() {
        let timer = PomodoroTimer(duration: 10)
        timer.configure(duration: 30)
        XCTAssertEqual(timer.duration, 30)
        XCTAssertEqual(timer.remaining, 30)
        XCTAssertEqual(timer.state, .idle)
    }

    func testConfigureHonoredWhenFinished() {
        let timer = PomodoroTimer(duration: 1)
        timer.start()
        timer.tick()
        XCTAssertEqual(timer.state, .finished)
        timer.configure(duration: 20)
        XCTAssertEqual(timer.duration, 20)
        XCTAssertEqual(timer.state, .idle)
    }

    // MARK: - Non-positive duration clamp

    func testNonPositiveDurationClampsToOne() {
        let timer = PomodoroTimer(duration: 0)
        XCTAssertEqual(timer.duration, 1)
        XCTAssertEqual(timer.remaining, 1)
    }

    func testNegativeDurationClampsToOne() {
        let timer = PomodoroTimer(duration: -5)
        XCTAssertEqual(timer.duration, 1)
    }

    func testConfigureNonPositiveClampsToOne() {
        let timer = PomodoroTimer(duration: 10)
        timer.configure(duration: 0)
        XCTAssertEqual(timer.duration, 1)
    }

    // MARK: - Reset

    func testResetFromRunning() {
        let timer = PomodoroTimer(duration: 10)
        timer.start()
        timer.tick()
        timer.reset()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.remaining, 10)
    }

    func testResetFromFinished() {
        let timer = PomodoroTimer(duration: 1)
        timer.start()
        timer.tick()
        timer.reset()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.remaining, 1)
    }

    func testResetFromIdle() {
        let timer = PomodoroTimer(duration: 10)
        timer.reset()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.remaining, 10)
    }

    // MARK: - Start after finished

    func testStartAfterFinishedRunsCleanly() {
        let timer = PomodoroTimer(duration: 2)
        timer.start()
        timer.tick()
        timer.tick()
        XCTAssertEqual(timer.state, .finished)
        timer.start()
        XCTAssertEqual(timer.state, .running)
        XCTAssertEqual(timer.remaining, 2)
    }

    func testConfigureThenStartAfterFinished() {
        let timer = PomodoroTimer(duration: 1)
        timer.start()
        timer.tick()
        timer.configure(duration: 5)
        timer.start()
        XCTAssertEqual(timer.state, .running)
        XCTAssertEqual(timer.remaining, 5)
    }

    // MARK: - Start while running/paused is no-op

    func testStartWhileRunningIsNoOp() {
        let timer = PomodoroTimer(duration: 10)
        timer.start()
        timer.tick()
        timer.start()
        XCTAssertEqual(timer.remaining, 9, "start() must not restart mid-run")
    }

    func testStartWhilePausedIsNoOp() {
        let timer = PomodoroTimer(duration: 10)
        timer.start()
        timer.tick()
        timer.pause()
        timer.start()
        XCTAssertEqual(timer.remaining, 9)
        XCTAssertEqual(timer.state, .paused)
    }

    // MARK: - Tick clamps at 0

    func testLargeTickClampsAtZero() {
        let timer = PomodoroTimer(duration: 5)
        var finishCount = 0
        timer.onFinish = { finishCount += 1 }
        timer.start()
        timer.tick(by: 100)
        XCTAssertEqual(timer.remaining, 0)
        XCTAssertEqual(timer.state, .finished)
        XCTAssertEqual(finishCount, 1)
    }

    // MARK: - formatted

    func testFormattedZero() {
        XCTAssertEqual(PomodoroTimer.formatted(0), "00:00")
    }

    func testFormattedFiveSeconds() {
        XCTAssertEqual(PomodoroTimer.formatted(5), "00:05")
    }

    func testFormattedSixtyFiveSeconds() {
        XCTAssertEqual(PomodoroTimer.formatted(65), "01:05")
    }

    func testFormatted1500Seconds() {
        XCTAssertEqual(PomodoroTimer.formatted(1500), "25:00")
    }

    func testFormattedFractionalRoundsDown() {
        XCTAssertEqual(PomodoroTimer.formatted(65.9), "01:05")
    }

    func testFormattedNegativeReturnsZero() {
        XCTAssertEqual(PomodoroTimer.formatted(-1), "00:00")
    }

    func testFormattedLargeMinutes() {
        XCTAssertEqual(PomodoroTimer.formatted(90 * 60), "90:00")
    }
}
