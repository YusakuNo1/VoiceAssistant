class ChatHistoryManager{
    static let shared = ChatHistoryManager()

    private var _chatId: String?
    var chatId: String? {
        get { return self._chatId }
        set { self._chatId = newValue }
    }
    private var chatHistory: [Message] = []
    private var chatHistoryUpdateListeners: [String: (() -> Void)] = [:]
    private var achievedChatHistory: [String: [Message]] = [:]
    
    private init() {}

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
