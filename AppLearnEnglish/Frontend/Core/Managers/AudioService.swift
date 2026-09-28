//
//  AudioService.swift
//  AppLearnEnglish
//

import Foundation
import Combine
import AVFoundation

class AudioService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = AudioService()
    
    private var audioPlayer: AVPlayer?
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    @Published var isPlaying: Bool = false
    @Published var activeWord: String? = nil
    
    private override init() {
        super.init()
        speechSynthesizer.delegate = self
        
        // Configure AVAudioSession to allow audio output in silent mode/headphones
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
        }
    }
    
    // MARK: - Play pronunciation
    func playPronunciation(word: String, audioUrlString: String? = nil) {
        // If an audio URL is provided and valid, try to play it
        if let audioUrlString = audioUrlString,
           let url = URL(string: audioUrlString),
           !audioUrlString.isEmpty {
            
            isPlaying = true
            activeWord = word
            
            let playerItem = AVPlayerItem(url: url)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerItem
            )
            
            audioPlayer = AVPlayer(playerItem: playerItem)
            audioPlayer?.play()
            
        } else {
            // Fallback to local Text-To-Speech (TTS)
            speakLocal(word: word)
        }
    }
    
    private func speakLocal(word: String) {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45 // Clear and easily understandable speaking speed
        
        isPlaying = true
        activeWord = word
        
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - Stop Audio / TTS Playback
    func stop() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        audioPlayer?.pause()
        audioPlayer = nil
        isPlaying = false
        activeWord = nil
    }
    
    // MARK: - AVPlayer Notification
    @objc private func playerDidFinishPlaying() {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.activeWord = nil
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.activeWord = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.activeWord = nil
        }
    }
}
