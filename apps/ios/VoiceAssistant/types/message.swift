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
        case image_url = "image_url"
    }

    let type: ContentType
    let text: String?
    let image_url: MessageContentImageUrlContent?
    
    init(text: String) {
        self.type = .text
        self.text = text
        self.image_url = nil
    }
    
    init(image_url: String) {
        self.type = .image_url
        self.text = nil
        self.image_url = MessageContentImageUrlContent(url: image_url)
    }
    
    init(image: Image) {
        self.type = .image_url
        self.text = nil
        self.image_url = MessageContentImageUrlContent(url: image.toDataURL())
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case image_url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(ContentType.self, forKey: .type)
        
        switch type {
        case .text:
            self.text = try container.decode(String.self, forKey: .text)
            self.image_url = nil
        case .image_url:
            self.text = nil
            self.image_url = try container.decode(MessageContentImageUrlContent.self, forKey: .image_url)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)

        switch self.type {
        case .text:
            try container.encode(text, forKey: .text)
        case .image_url:
            try container.encode(image_url, forKey: .image_url)
        }
    }
}
