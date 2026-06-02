# Test Results

**Status: ALL TESTS PASSED**

## Run command
```
swift test
```
Run from: `/Users/vimal/open-source/tamatar`
Date: 2026-06-02

## Summary
- **33 tests executed, 0 failures, 0 unexpected failures**
- Build time: 5.74s
- Test time: 0.003s

## Test suite: `PomodoroTimerTests`

| Test | Result |
|---|---|
| testStartSetsRunningWithFullDuration | ✅ passed |
| testTicksDecrementRemaining | ✅ passed |
| testTickingToZeroSetsFinishedAndFiresOnFinish | ✅ passed |
| testOnFinishFiresExactlyOnceWithExtraTicks | ✅ passed |
| testTickIsNoOpWhenIdle | ✅ passed |
| testTickIsNoOpWhenPaused | ✅ passed |
| testTickIsNoOpWhenFinished | ✅ passed |
| testPauseThenTickDoesNotDecrement | ✅ passed |
| testResumeThenTickDecrements | ✅ passed |
| testPauseWhenNotRunningIsNoOp | ✅ passed |
| testResumeWhenNotPausedIsNoOp | ✅ passed |
| testConfigureIgnoredWhileRunning | ✅ passed |
| testConfigureIgnoredWhilePaused | ✅ passed |
| testConfigureHonoredWhenIdle | ✅ passed |
| testConfigureHonoredWhenFinished | ✅ passed |
| testNonPositiveDurationClampsToOne | ✅ passed |
| testNegativeDurationClampsToOne | ✅ passed |
| testConfigureNonPositiveClampsToOne | ✅ passed |
| testResetFromRunning | ✅ passed |
| testResetFromFinished | ✅ passed |
| testResetFromIdle | ✅ passed |
| testStartAfterFinishedRunsCleanly | ✅ passed |
| testConfigureThenStartAfterFinished | ✅ passed |
| testStartWhileRunningIsNoOp | ✅ passed |
| testStartWhilePausedIsNoOp | ✅ passed |
| testLargeTickClampsAtZero | ✅ passed |
| testFormattedZero | ✅ passed |
| testFormattedFiveSeconds | ✅ passed |
| testFormattedSixtyFiveSeconds | ✅ passed |
| testFormatted1500Seconds | ✅ passed |
| testFormattedFractionalRoundsDown | ✅ passed |
| testFormattedNegativeReturnsZero | ✅ passed |
| testFormattedLargeMinutes | ✅ passed |

## Coverage by spec requirement

| Spec requirement | Tests covering it |
|---|---|
| Happy path: start → running, tick → decrement | testStartSetsRunningWithFullDuration, testTicksDecrementRemaining |
| Ticking to 0 → finished + onFinish fires once | testTickingToZeroSetsFinishedAndFiresOnFinish, testOnFinishFiresExactlyOnceWithExtraTicks |
| tick no-op when idle/paused/finished | testTickIsNoOpWhenIdle, testTickIsNoOpWhenPaused, testTickIsNoOpWhenFinished |
| Pause/resume behaviour | testPauseThenTickDoesNotDecrement, testResumeThenTickDecrements, testPauseWhenNotRunningIsNoOp, testResumeWhenNotPausedIsNoOp |
| configure ignored while running/paused | testConfigureIgnoredWhileRunning, testConfigureIgnoredWhilePaused |
| configure honored when idle/finished | testConfigureHonoredWhenIdle, testConfigureHonoredWhenFinished |
| Non-positive duration clamped to 1 (failure/edge case) | testNonPositiveDurationClampsToOne, testNegativeDurationClampsToOne, testConfigureNonPositiveClampsToOne |
| reset from any state | testResetFromRunning, testResetFromFinished, testResetFromIdle |
| start after finished runs cleanly | testStartAfterFinishedRunsCleanly, testConfigureThenStartAfterFinished |
| start while running/paused is no-op | testStartWhileRunningIsNoOp, testStartWhilePausedIsNoOp |
| Large tick clamped at 0 | testLargeTickClampsAtZero |
| formatted: 0, 5, 65, 1500, fractional, negative, 90-min | testFormattedZero, testFormattedFiveSeconds, testFormattedSixtyFiveSeconds, testFormatted1500Seconds, testFormattedFractionalRoundsDown, testFormattedNegativeReturnsZero, testFormattedLargeMinutes |

## Notes

The AppKit UI targets (`Tamatar`, `AppDelegate`, `TimeUpWindow`) are not covered by
automated tests — this is by design (spec assumption 2: UI is not CLI-testable).
Manual smoke testing of the menu-bar app is required separately.
