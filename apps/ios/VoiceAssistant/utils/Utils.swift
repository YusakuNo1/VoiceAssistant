class Utils {
    static func parseJSON<T>(_ type: T.Type, from data: Data) throws -> T? where T : Decodable {
        var responseString = String(data: data, encoding: .utf8)!
        responseString.replace("\\", with: "\\\\")
        return try? JSONDecoder().decode(type, from: Data(responseString.utf8))
    }
}
