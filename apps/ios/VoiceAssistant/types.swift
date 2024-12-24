enum Role: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

struct Message: Codable {
    let role: Role
    let content: String
}

struct ChatHistoryResponse: Codable {
    let messages: [Message]
}

struct LanguageModelRequestBody: Codable {
    let messages: [Message]
}

struct Credentials: Codable {
    struct Speech: Codable {
        let key: String
        let region: String
    }
    
    let speech: Speech
}
