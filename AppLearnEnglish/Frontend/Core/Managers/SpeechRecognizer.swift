//
//  SpeechRecognizer.swift
//  AppLearnEnglish
//

import Foundation
import Speech
import AVFoundation
import Combine

class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var errorMessage: String? = nil
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) // English pronunciation
    
    init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.permissionGranted = true
                default:
                    self.permissionGranted = false
                    self.errorMessage = "Vui lòng cấp quyền nhận diện giọng nói và microphone trong cài đặt hệ thống."
                }
            }
        }
    }
    
    func startRecording() {
        guard permissionGranted else {
            self.errorMessage = "Chưa có quyền ghi âm/nhận diện giọng nói."
            return
        }
        
        // Stop any active tasks
        stopRecording()
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest, let inputNode = inputNode else {
            self.errorMessage = "Không thể khởi tạo bộ ghi âm."
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        transcript = ""
        isRecording = true
        errorMessage = nil
        
        // Configure Audio Session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.errorMessage = "Lỗi cấu hình thiết bị âm thanh: \(error.localizedDescription)"
            self.isRecording = false
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            
            if let error = error {
                print("Speech recognition error: \(error)")
                // Do not throw error on abort or cancel
                let nsError = error as NSError
                if nsError.code != 301 && nsError.code != 4 { // Aborted or cancelled
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            self.errorMessage = "Lỗi khởi động ghi âm: \(error.localizedDescription)"
            self.stopRecording()
        }
    }
    
    func stopRecording() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        inputNode = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        // Restore audio playback session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .default, options: [])
        try? audioSession.setActive(true)
    }
    
    // Compare two strings and calculate matching percentage (0 to 100)
    func calculateAccuracy(target: String, spoken: String) -> Int {
        let cleanTarget = target.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
        let cleanSpoken = spoken.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
        
        if cleanTarget.isEmpty || cleanSpoken.isEmpty { return 0 }
        if cleanTarget == cleanSpoken { return 100 }
        
        let targetWords = cleanTarget.components(separatedBy: " ")
        let spokenWords = cleanSpoken.components(separatedBy: " ")
        
        var matchCount = 0
        for word in spokenWords {
            if targetWords.contains(word) {
                matchCount += 1
            }
        }
        
        let ratio = Double(matchCount) / Double(max(targetWords.count, spokenWords.count))
        return Int(ratio * 100)
    }
}
