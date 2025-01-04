import AVFoundation


class AbstractSpeechManager {
    internal let apiManager: ApiManager!
    internal let updateProgress: (ProgressState) -> Void

    internal var audioEngine: AVAudioEngine = AVAudioEngine()

    internal var busId: AVAudioNodeBus = 0
    internal var sampleRate = 16000
    internal var bufferSize = 2048

    init(apiManager: ApiManager, updateProgress: @escaping (ProgressState) -> Void) {
        self.apiManager = apiManager
        self.updateProgress = updateProgress
    }

    func recognize(imageList: [Image]) {
        fatalError("Not implemented")
    }
    
    func stopSpeechRecognize(imageList: [Image]) {
//        fatalError("Not implemented")
    }

    func synthesize(text: String) {
        fatalError("Not implemented")
    }

    func _setAudioMode(mode: AudioMode) {
        do {
            if mode == AudioMode.Playback {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            } else if mode == AudioMode.Record {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord, with: .mixWithOthers)
            }
            
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio mode: \(error.localizedDescription)")
        }
    }
    
    func _onSpeechRecognized(message: String, imageList: [Image]) {
        self.updateProgress(.WaitForRes)
        self.apiManager.sendChatMessages(message: message, imageList: imageList) { (result) -> Void in
            switch result {
            case .success(let respnoseString):
                self.synthesize(text: respnoseString)
            case .failure(let error):
                print("Error sending message: \(error)")
            }
        }
    }
}
