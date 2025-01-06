import AVFoundation


class AbstractSpeech: NSObject {
    internal var _busId: AVAudioNodeBus = 0
    internal var _sampleRate = 16000
    internal var _bufferSize = 2048

    internal var _audioEngine: AVAudioEngine = AVAudioEngine()

    internal var _updateProgress: ((ProgressState) -> Void)?
    var updateProgress: ((ProgressState) -> Void)? {
        get { _updateProgress }
        set { _updateProgress = newValue }
    }

    override init() {}
    
    func recognize(imageList: [Image]) {
        fatalError( "recognize() must be implemented by subclasses")
    }
    
    func synthesize(text: String) {
        fatalError( "synthesize() must be implemented by subclasses")
    }
    
    internal func _setAudioMode(mode: AudioMode) {
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
    
    internal func _onSpeechRecognized(message: String, imageList: [Image]) {
        self._updateProgress?(.WaitForRes)
        ApiManager.shared.sendChatMessages(message: message, imageList: imageList) { (result) -> Void in
            switch result {
            case .success(let respnoseString):
                self.synthesize(text: respnoseString)
            case .failure(let error):
                print("Error sending message: \(error)")
            }
        }
    }
}
