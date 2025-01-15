import AVFoundation


class AbstractSpeech: NSObject {
    internal let _busId: AVAudioNodeBus = 0
    internal let _sampleRate = 16000
    internal let _bufferSize = 2048
    internal var _audioPlayerVolume: Float = 1.0
    
    internal let _audioEngine: AVAudioEngine = AVAudioEngine()
    
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
                self._onSpeechRecognizedSuccess(respnoseString: respnoseString)
            case .failure(let error):
                print("Error sending message: \(error)")
            }
        }
    }
    
    internal func _onSpeechRecognizedSuccess(respnoseString: String) {
        do {
            // Test responseString is JSON string or not, if yes, handle is as action
            let jsonDecoder = JSONDecoder()
            let responseData = respnoseString.data(using: .utf8)!
            let action = try jsonDecoder.decode(Action.self, from: responseData)
            self._onSpeechRecognizedSuccessAction(action: action)
        } catch {
            self.synthesize(text: respnoseString)
        }
    }
    
    internal func _onSpeechRecognizedSuccessAction(action: Action) {
        if action.actionType == ActionType.changeVolume {
            if let volumeRaw = action.data["volume"] {
                switch volumeRaw {
                case .int(let volume):
                    if volume >= 0 && volume <= 100 {
                        self._audioPlayerVolume = Float(volume) / 100
                        self.synthesize(text: ACTION_SUCCESS_MESSAGE)
                    } else {
                        self.synthesize(text: ACTION_FAILURE_MESSAGE_CHANGE_VOLUME)
                    }
                case .string(let volumeString):
                    Logger.log(.error, "Unsupported volume format: \(volumeString)")
                    self.synthesize(text: ACTION_FAILURE_MESSAGE_CHANGE_VOLUME)
                }
            }
        }
    }
}
