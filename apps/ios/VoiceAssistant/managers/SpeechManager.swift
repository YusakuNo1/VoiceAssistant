import AVFoundation

let USE_REMOTE_SPEECH = true

class SpeechManager {
    static let shared = SpeechManager()
    
    private var _chatId: String?
    var chatId: String? {
        get { return self._chatId }
        set { self._chatId = newValue }
    }
    private var chatHistory: [Message] = []
    private var chatHistoryUpdateListeners: [String: (() -> Void)] = [:]
    private var achievedChatHistory: [String: [Message]] = [:]
    
    private let _mediaManager: MediaManager
    var mediaManager: MediaManager {
        get { return self._mediaManager }
    }
    
    private let _apiManager: ApiManager
    var apiManager: ApiManager {
        get { return self._apiManager }
    }
    
    private let _speech: AbstractSpeech
    var speech: AbstractSpeech {
        get { return self._speech }
    }
    
    private init() {
        self._apiManager = ApiManager()
        self._mediaManager = MediaManager()
        if USE_REMOTE_SPEECH {
            self._speech = RemoteSpeech(apiManager: self._apiManager)
        } else {
            self._speech = LocalSpeech(apiManager: self._apiManager)
        }
    }
    
    // MARK: - Public methods
    
    func recognize() {
        let imageList = mediaManager.imageList
        self._speech.recognize(imageList: imageList)
    }
    
    func synthesize(text: String) {
        self._speech.synthesize(text: text)
    }
    
    // MARK: - Message history
    
    func getChatHistory() -> [Message] {
        return self.chatHistory
    }
    
    func getChatMessage(index: Int) -> Message? {
        if index < self.chatHistory.count {
            return self.chatHistory[index]
        } else {
            return nil
        }
    }

    func appendChatMessages(messages: [Message]) {
        self.chatHistory.append(contentsOf: messages)
        self._onChatHistoryUpdated()
    }
    
    func clearChatHistory() {
        if let chatId = self.chatId {
            self.achievedChatHistory[chatId] = self.chatHistory
        }
        self.chatHistory.removeAll()
        self._onChatHistoryUpdated()
    }
    
    func registerChatHistoryUpdateListener(listenerKey: String, listener: @escaping () -> Void) {
        self.chatHistoryUpdateListeners[listenerKey] = listener
    }
    
    func unregisterChatHistoryUpdateListener(listenerKey: String) {
        self.chatHistoryUpdateListeners[listenerKey] = nil
    }
    
    private func _onChatHistoryUpdated() {
        for listenerKey in self.chatHistoryUpdateListeners.keys {
            self.chatHistoryUpdateListeners[listenerKey]?()
        }
    }
}
