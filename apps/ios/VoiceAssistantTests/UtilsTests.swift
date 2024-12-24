import Testing
@testable import VoiceAssistant


struct UtilsTests {
    @Test func testParseJSON() async throws {
        struct People: Codable {
            let name: String
            let age: Int
        }

        let inputStr = """
        { "name": "John", "age": 25 }
        """
        let data: Data = Data(inputStr.utf8)
        let result = try? Utils.parseJSON(People.self, from: data)
        assert(result?.name == "John")
        assert(result?.age == 25)
    }
    
    @Test func testParseJSONWithEscapeChar() async throws {
        struct Description : Codable {
            let description: String
        }

        let inputStr = """
        { "description": "First line\\tSecond line" }
        """
        let data: Data = Data(inputStr.utf8)
        let result = try? Utils.parseJSON(Description.self, from: data)
        assert(result?.description == "First line\\tSecond line")
    }
}
