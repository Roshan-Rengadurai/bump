import Foundation
import AVFoundation
import AppKit

/// Plays a combo-hit sound with pure pitch shifting (no speed change) via
/// AVAudioEngine + AVAudioUnitTimePitch. Each combo tier adds ~200 cents
/// (≈2 semitones), capped at tier 10.
@MainActor
final class SoundPlayer {
    private var clipURLs: [URL] = []

    // Each active playback gets its own engine; retained here until done.
    private struct ActivePlay {
        let engine: AVAudioEngine
        let player: AVAudioPlayerNode
        let endsAt: Date
    }
    private var live: [ActivePlay] = []

    var volume: Float = 0.9

    init() { loadClips() }

    var hasClips: Bool { !clipURLs.isEmpty }
    func reload() { loadClips() }

    private func loadClips() {
        let exts = ["wav", "mp3", "m4a", "aiff", "aif", "caf"]
        var urls: [URL] = []

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let userDir = appSupport.appendingPathComponent("Bump/Sounds", isDirectory: true)
        for ext in exts {
            urls += (try? FileManager.default.contentsOfDirectory(at: userDir, includingPropertiesForKeys: nil))?
                .filter { $0.pathExtension.lowercased() == ext } ?? []
        }
        for ext in exts {
            urls += Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Sounds") ?? []
        }
        clipURLs = urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Play a random clip with pitch shifted up by ~200 cents × (tier-1), capped at tier 10.
    /// Speed/tempo is unchanged — only pitch moves.
    func play(tier: Int = 1) {
        prune()

        guard let url = clipURLs.randomElement() else {
            let snd = NSSound(contentsOfFile: "/System/Library/Sounds/Funk.aiff", byReference: false)
            snd?.volume = 0.7; snd?.play()
            return
        }

        guard let file = try? AVAudioFile(forReading: url) else { return }

        let engine  = AVAudioEngine()
        let player  = AVAudioPlayerNode()
        let pitch   = AVAudioUnitTimePitch()

        // 100 cents = 1 semitone per tier, cap at tier 10 (9 semitones up)
        pitch.pitch = Float(min(tier - 1, 9)) * 100.0

        engine.attach(player)
        engine.attach(pitch)

        let fmt = file.processingFormat
        engine.connect(player, to: pitch, format: fmt)
        engine.connect(pitch, to: engine.mainMixerNode, format: fmt)
        engine.mainMixerNode.outputVolume = volume

        guard (try? engine.start()) != nil else { return }

        let duration = Double(file.length) / fmt.sampleRate
        player.scheduleFile(file, at: nil, completionHandler: nil)
        player.play()

        live.append(ActivePlay(engine: engine, player: player, endsAt: Date().addingTimeInterval(duration + 0.3)))
    }

    private func prune() {
        let now = Date()
        live.removeAll { ap in
            if now > ap.endsAt { ap.engine.stop(); return true }
            return false
        }
    }
}
