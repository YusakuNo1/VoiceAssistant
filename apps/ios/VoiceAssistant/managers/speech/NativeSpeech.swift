import AVFoundation
import UIKit
import Speech


class ThrottleHandler {
    private var workItem: DispatchWorkItem?
    private let queue = DispatchQueue.main
    private let delay: TimeInterval = 1.0
    
    var action: (() -> Void)? = nil
    
    func triggerAction() {
        // Cancel the previous work item if the function is called again within 1 second
        workItem?.cancel()

        // Create a new work item
        let newWorkItem = DispatchWorkItem { [weak self] in
//            self?.performAction()
            self?.action?()
        }

        // Store the new work item
        workItem = newWorkItem

        // Schedule execution after delay
        queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }

//    private func performAction() {
//        print("Action triggered!")
//        // Place your function call here
//    }
}

class NativeSpeech: AbstractSpeech, ObservableObject {
    enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        
        var message: String {
            switch self {
            case .nilRecognizer: return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
            case .notPermittedToRecord: return "Not permitted to record audio"
            case .recognizerIsUnavailable: return "Recognizer is unavailable"
            }
        }
    }
    
    @MainActor var transcript: String = ""
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private let throttleHandler = ThrottleHandler()
    
    override init() {
        super.init()
        recognizer = SFSpeechRecognizer()
        guard recognizer != nil else {
            transcribe(RecognizerError.nilRecognizer)
            return
        }
        
        Task {
            do {
                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                    throw RecognizerError.notAuthorizedToRecognize
                }
                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                    throw RecognizerError.notPermittedToRecord
                }
            } catch {
                transcribe(error)
            }
        }
    }
    
//    @MainActor func startTranscribing() {
//        Task {
//            await transcribe()
//        }
//    }
//    
//    @MainActor func resetTranscript() {
//        Task {
//            await reset()
//        }
//    }
//    
//    @MainActor func stopTranscribing() {
//        Task {
//            await reset()
//        }
//    }
    
    override func recognize(imageList: [Image]) {
        self._setAudioMode(mode: .Record)

        Task {
            transcribe(imageList: imageList)
        }
    }
    
    override func synthesize(text: String) {
    }
    
    private func transcribe(imageList: [Image]) {
        guard let recognizer, recognizer.isAvailable else {
            self.transcribe(RecognizerError.recognizerIsUnavailable)
            return
        }
        
        do {
            let (audioEngine, request) = try Self.prepareEngine()
            self.audioEngine = audioEngine
            self.request = request
            self.task = recognizer.recognitionTask(with: request, resultHandler: { [weak self] result, error in
                self?.recognitionHandler(imageList: imageList, audioEngine: audioEngine, result: result, error: error)
            })
        } catch {
            self.reset()
            self.transcribe(error)
        }
    }
    
    private func reset() {
        task?.cancel()
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        task = nil
    }
    
    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
    
    nonisolated private func recognitionHandler(imageList: [Image], audioEngine: AVAudioEngine, result: SFSpeechRecognitionResult?, error: Error?) {
        let receivedFinalResult = result?.isFinal ?? false
        let receivedError = error != nil
        
        if receivedFinalResult || receivedError {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        if let result {
            transcribe(result.bestTranscription.formattedString)
            
            // Set a timer, if the next call of recognitionHandler comes within 1 second, no nothing and set a new timer; if it doesn't come in 1 second, trigger a function call
            let message = result.bestTranscription.formattedString
            throttleHandler.action = { [weak self] in
                self?.reset()
                self?._onSpeechRecognized(message: message, imageList: imageList)
            }
            throttleHandler.triggerAction()
        }
    }
    
    nonisolated private func transcribe(_ message: String) {
        Task { @MainActor in
            transcript = message
            print("* * * Message: \(message)")
//            self._onSpeechRecognized(message: message, imageList: imageList)
        }
    }
    nonisolated private func transcribe(_ error: Error) {
        var errorMessage = ""
        if let error = error as? RecognizerError {
            errorMessage += error.message
        } else {
            errorMessage += error.localizedDescription
        }
        Task { @MainActor [errorMessage] in
            transcript = "<< \(errorMessage) >>"
        }
    }
}

extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

extension AVAudioSession {
    func hasPermissionToRecord() async -> Bool {
        await withCheckedContinuation { continuation in
            requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
}
