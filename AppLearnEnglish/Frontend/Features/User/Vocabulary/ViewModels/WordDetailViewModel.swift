//
//  WordDetailViewModel.swift
//  AppLearnEnglish
//

import Foundation
import SwiftUI
import Combine

class WordDetailViewModel: ObservableObject {
    let word: VocabularyWord
    
    @Published var isPlaying: Bool = false
    private let audioService = AudioService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(word: VocabularyWord) {
        self.word = word
        
        // Listen to AudioService isPlaying states to update our UI speaker icon wave animation
        audioService.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playingState in
                guard let self = self else { return }
                if self.audioService.activeWord == self.word.word {
                    self.isPlaying = playingState
                } else {
                    self.isPlaying = false
                }
            }
            .store(in: &cancellables)
    }
    
    // Play pronunciation via AudioService
    func playAudio() {
        audioService.playPronunciation(word: word.word, audioUrlString: word.audio)
    }
}
