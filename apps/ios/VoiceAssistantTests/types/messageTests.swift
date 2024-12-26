import Testing
@testable import VoiceAssistant


struct MessageTests {
    @Test func testEncodeMessage() async throws {
        let message = Message(role: Role.system, content: [
            MessageContent(text: "hello"),
            MessageContent(image_url: "my-protocol://image-url"),
        ])
        let jsonEncoder = JSONEncoder()
        let messageData = try jsonEncoder.encode(message)

        let jsonDecoder = JSONDecoder()
        let decodedMessage = try jsonDecoder.decode(Message.self, from: messageData)
        assert(decodedMessage.role == message.role)
        assert(decodedMessage.content == message.content)
        
        assert(decodedMessage.content[0].type == .text && decodedMessage.content[0].text == "hello")
        assert(decodedMessage.content[1].type == .image_url && decodedMessage.content[1].image_url?.url == "my-protocol://image-url")
        
        let jsonString = String(data: messageData, encoding: .utf8)!
        print(jsonString)
    }
}
