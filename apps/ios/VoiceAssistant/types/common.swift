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

enum ImageFormat: String, Codable {
    case png = "png"
    case jpeg = "jpeg"
}

struct Image: Codable {
    let width: CGFloat
    let height: CGFloat
    let format: ImageFormat
    let data: Data
    
    func toDataURL() -> String {
        let dataString = data.base64EncodedString()
        return "data:image/\(format);base64,\(dataString)"
    }
}
