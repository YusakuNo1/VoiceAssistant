struct Message: Codable {
    let role: String
    let content: String
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
