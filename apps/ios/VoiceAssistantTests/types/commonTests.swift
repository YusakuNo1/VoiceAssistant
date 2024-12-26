import Testing
@testable import VoiceAssistant


struct CommonTests {
    @Test func testImage() async throws {
        let data = Data("hello".utf8)
        let image = Image(width: 100, height: 200, format: .png, data: data)
        
        let jsonEncoder = JSONEncoder()
        let imageData = try jsonEncoder.encode(image)
        
        let jsonDecoder = JSONDecoder()
        let decodedImage = try jsonDecoder.decode(Image.self, from: imageData)
        assert(decodedImage.width == 100)
        assert(decodedImage.height == 200)
        // Convert Data to string
        let decodedString = String(decoding: decodedImage.data, as: UTF8.self)
        assert(decodedString == "hello")
    }
    
    @Test func testImageToDataUrl() async throws {
        let data = Data("hello".utf8)
        let image = Image(width: 100, height: 200, format: .png, data: data)
        let dataUrl = image.toDataURL()
        assert(dataUrl == "data:image/png;base64,aGVsbG8=")
    }
}
