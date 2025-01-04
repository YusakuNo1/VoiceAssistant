import AVFoundation

let USE_REMOTE_SPEECH = true

class SpeechManager {
//    static let shared = SpeechManager()

    internal let _mediaManager: MediaManager
    var mediaManager: MediaManager {
        get { return self._mediaManager }
    }

    internal let _apiManager: ApiManager
    var apiManager: ApiManager {
        get { return self._apiManager }
    }

    private let _speech: AbstractSpeech

    init(
        appendChatMessages: @escaping (String?, [Message]) -> Void,
        updateProgress: @escaping (ProgressState) -> Void
    ) {
        self._apiManager = ApiManager(appendChatMessages: appendChatMessages)
        self._mediaManager = MediaManager()

        if USE_REMOTE_SPEECH {
            self._speech = RemoteSpeech(apiManager: _apiManager, updateProgress: updateProgress)
        } else {
            self._speech = LocalSpeech(apiManager: _apiManager, updateProgress: updateProgress)
        }
    }

    func recognize(imageList: [Image]) {
        self._speech.recognize(imageList: imageList)
    }
    
    func synthesize(text: String) {
        self._speech.synthesize(text: text)
    }
}
