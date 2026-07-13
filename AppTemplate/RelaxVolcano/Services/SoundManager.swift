import AVFoundation
import Foundation

enum TimerSound: String, CaseIterable {
    case rain
    case forest
    case okean
    case lowFai = "low-fai"

    var title: String {
        switch self {
        case .rain: return "Rain"
        case .forest: return "Forest"
        case .okean: return "Ocean"
        case .lowFai: return "Lo-Fi"
        }
    }
}

final class SoundManager {
    static let shared = SoundManager()

    private var loopPlayer: AVAudioPlayer?
    private var buttonPlayer: AVAudioPlayer?

    private init() {}

    func playTimerLoop(sound: TimerSound) {
        stopTimerLoop()
        guard let player = loadPlayer(named: sound.rawValue) else { return }
        player.numberOfLoops = -1
        player.play()
        loopPlayer = player
    }

    func stopTimerLoop() {
        loopPlayer?.stop()
        loopPlayer = nil
    }

    func playButtonSound() {
        guard let player = loadPlayer(named: "button") else { return }
        player.numberOfLoops = 0
        player.play()
        buttonPlayer = player
    }

    func playCompletionSound() {
        guard let player = loadPlayer(named: "bell") else {
            return
        }
        player.numberOfLoops = 0
        player.play()
        buttonPlayer = player
    }

    private func loadPlayer(named fileName: String) -> AVAudioPlayer? {
        let candidates = ["mp3", "m4a", "wav", "caf"]
        for ext in candidates {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                return player
            }
        }
        return nil
    }
}
