struct ChatHistoryResponse: Codable {
    let messages: [Message]
}

struct LanguageModelRequestBody: Codable {
    let messages: [Message]
}

struct SpeechSynthesizeRequestBody: Codable {
    let text: String
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

enum StringOrIntEnum: Codable {
    case string(String)
    case int(Int)
    
    init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(string)
        } else if let int = try? decoder.singleValueContainer().decode(Int.self) {
            self = .int(int)
        } else {
            self = .string("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .int(let int):
            try container.encode(int)
        }
    }}
