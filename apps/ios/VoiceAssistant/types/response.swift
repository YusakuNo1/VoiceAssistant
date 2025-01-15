import Foundation

enum Platform: String, CaseIterable, Codable {
    case ios = "ios"
    case web = "web"
}

enum ActionType: String, CaseIterable, Codable {
    case getWeather = "get_weather"
    case changeVolume = "change_volume"
    case openBrowser = "open_browser"
}

struct Action: Codable {
    let platform: Platform
    let actionType: ActionType
    let data: [String: StringOrIntEnum]
    
    enum CodingKeys: String, CodingKey {
         case platform
         case actionType
         case data
     }

     func encode(to encoder: Encoder) throws {
         var container = encoder.container(keyedBy: CodingKeys.self)
         try container.encode(platform.rawValue, forKey: .platform)
         try container.encode(actionType.rawValue, forKey: .actionType)
         try container.encode(data, forKey: .data)
     }

     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         self.platform = try container.decode(Platform.self, forKey: .platform)
         self.actionType = try container.decode(ActionType.self, forKey: .actionType)
         self.data = try container.decode([String: StringOrIntEnum].self, forKey: .data)
     }
}
