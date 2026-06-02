import AVFoundation
import AppKit

private let mutedDefaultsKey = "com.tamatar.tickingMuted"

/// Plays a short mechanical clock-style tick while the timer runs.
final class TickingSoundPlayer {
    private(set) var isMuted: Bool

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var tickBuffer: AVAudioPCMBuffer?
    private var isEngineReady = false

    init() {
        isMuted = UserDefaults.standard.bool(forKey: mutedDefaultsKey)
    }

    func playTick() {
        guard !isMuted else { return }
        prepareEngineIfNeeded()
        guard let tickBuffer else { return }
        if player.isPlaying { player.stop() }
        player.scheduleBuffer(tickBuffer, at: nil, options: [], completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        UserDefaults.standard.set(muted, forKey: mutedDefaultsKey)
        if muted, player.isPlaying { player.stop() }
    }

    private func prepareEngineIfNeeded() {
        guard !isEngineReady else { return }

        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2) else {
            return
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: format)

        tickBuffer = Self.makeClockTickBuffer(format: format)

        engine.prepare()
        do {
            try engine.start()
            isEngineReady = true
        } catch {
            tickBuffer = nil
        }
    }

    /// Synthesizes a mechanical tick: impulse click + brief escapement ring.
    private static func makeClockTickBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        let duration = 0.032
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else { return nil }

        buffer.frameLength = frameCount

        var mono = [Float](repeating: 0, count: Int(frameCount))
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Hammer / pallet strike: broadband click, dies in a few ms.
            let clickEnvelope = exp(-t * 380)
            let click = pseudoNoise(i) * clickEnvelope * 0.6

            // Escapement resonance: short metallic ring after the strike.
            let ringEnvelope = exp(-t * 95)
            let ring = sin(2 * .pi * 2_150 * t) * ringEnvelope * 0.24

            // Faint wooden case thump.
            let thumpEnvelope = exp(-t * 65)
            let thump = sin(2 * .pi * 480 * t) * thumpEnvelope * 0.1

            mono[i] = Float(click + ring + thump)
        }

        normalize(&mono, peak: 0.82)

        for channel in 0..<channelCount {
            guard let samples = buffer.floatChannelData?[channel] else { continue }
            for i in 0..<Int(frameCount) {
                samples[i] = mono[i]
            }
        }

        return buffer
    }

    private static func pseudoNoise(_ index: Int) -> Double {
        let x = sin(Double(index) * 12.9898 + 78.233) * 43_758.5453
        return (x - floor(x)) * 2 - 1
    }

    private static func normalize(_ samples: inout [Float], peak targetPeak: Float) {
        guard let maxSample = samples.map({ abs($0) }).max(), maxSample > targetPeak else {
            return
        }
        let scale = targetPeak / maxSample
        for i in samples.indices {
            samples[i] *= scale
        }
    }
}
