enum Role: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

struct Message: Codable {
    var role: Role
    var content: [MessageContent]
}

struct MessageContentImageUrlContent: Codable, Equatable {
    let url: String
}

struct MessageContent: Codable, Equatable {
    enum ContentType: String, Codable {
        case text = "text"
        case imageUrl = "image_url"
    }

    let type: ContentType
    let text: String?
    let imageUrl: MessageContentImageUrlContent?
    
    init(text: String) {
        self.type = .text
        self.text = text
        self.imageUrl = nil
    }
    
    init(imageUrl: String) {
        self.type = .imageUrl
        self.text = nil
        self.imageUrl = MessageContentImageUrlContent(url: imageUrl)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(ContentType.self, forKey: .type)
        
        switch type {
        case .text:
            self.text = try container.decode(String.self, forKey: .text)
            self.imageUrl = nil
        case .imageUrl:
            self.text = nil
            self.imageUrl = try container.decode(MessageContentImageUrlContent.self, forKey: .imageUrl)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)

        switch self.type {
        case .text:
            try container.encode(text, forKey: .text)
        case .imageUrl:
            try container.encode(imageUrl, forKey: .imageUrl)
        }
    }
}
