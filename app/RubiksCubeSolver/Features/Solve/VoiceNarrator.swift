import AVFoundation
import Foundation

/// Thin wrapper around `AVSpeechSynthesizer`. Single-voice, interruptible.
@MainActor
final class VoiceNarrator: ObservableObject {
    @Published var enabled: Bool = true

    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String) {
        guard enabled else { return }
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        utterance.pitchMultiplier = 1.0
        synth.speak(utterance)
    }

    func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    }
}
