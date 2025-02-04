import AVFoundation

let USE_REMOTE_SPEECH = true

class SpeechManager {
    static let shared = SpeechManager()

    private let _speech: AbstractSpeech
    var speech: AbstractSpeech {
        get { return self._speech }
    }
    
    private init() {
        self._speech = NativeSpeech()
//        if USE_REMOTE_SPEECH {
//            self._speech = RemoteSpeech()
//        } else {
//            self._speech = LocalSpeech()
//        }
    }
    
    // MARK: - Public methods
    
    func recognize() {
        self._speech.recognize(imageList: MediaManager.shared.imageList)
    }
    
    func synthesize(text: String) {
        self._speech.synthesize(text: text)
    }
}
