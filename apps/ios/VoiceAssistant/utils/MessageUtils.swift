class MessageUtils {
    static func buildMessages(message: String, imageList: [Image]) -> [Message] {
        var messageContentList = [MessageContent(text: message)]
        for image in imageList {
            messageContentList.append(MessageContent(image: image))
        }
        let messages = [Message(role: Role.user, content: messageContentList)]
        return messages
    }
}
