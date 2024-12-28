import UIKit

enum CellId: String {
    case user = "cell-user"
    case assistant = "cell-assistant"
}

class ChatTable: NSObject, UITableViewDelegate, UITableViewDataSource {
    private var chatId: String?
    private var chatHistory: [Message] = []

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create cells from story board, for roles of "user", create with ID "cell-user", otherwise, create with ID "cell-assistant"
        var cell: ChatTableCell?
        if chatHistory[indexPath.row].role == Role.user {
            cell = tableView.dequeueReusableCell(withIdentifier: CellId.user.rawValue, for: indexPath) as? ChatTableCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: CellId.assistant.rawValue, for: indexPath) as? ChatTableCell
        }
        
        guard let cell = cell else {
            return UITableViewCell()
        }

        cell.contentLabelContainer.layer.cornerRadius = 10
        cell.contentLabelContainer.layer.borderWidth = 2
        cell.contentLabelContainer.layer.backgroundColor = UIColor.yellow.cgColor
        cell.contentLabelContainer.layer.borderColor = UIColor.lightGray.cgColor
        cell.contentLabelContainer.layer.masksToBounds = true
        
        // Assumption: only 1 "text" type
        var imageContentList: [MessageContent] = []
        for content in chatHistory[indexPath.row].content {
            if content.type == .text {
                cell.contentLabel.text = content.text ?? ""
            } else if content.type == .image_url {
                imageContentList.append(content)
            }
        }
        
        if imageContentList.count == 0 {
            cell.thumbnailContainerHeight.isActive = true
        } else {
            cell.thumbnailContainerHeight.isActive = false
            for index in 0..<MAX_CELL_THUMBNAILS {
                let imageView = cell.thumbnails[index]
                if index < imageContentList.count {
                    imageView.isHidden = false
                    if let dataUrl = imageContentList[index].image_url?.url, let image = ImageUtils.imageFromDataUrl(dataUrl: dataUrl) {
                        imageView.image = image
                    }
                } else {
                    imageView.isHidden = true
                }
            }
        }
        
        return cell
    }
    
    func appendChatMessages(_ chatId: String?, _ messages: [Message]) {
        if chatId != self.chatId {
            if self.chatId != nil {
                // If the previous chat is available, clear the history
                self.chatHistory.removeAll()
            }
            self.chatId = chatId
        }

        for message in messages {
            chatHistory.append(message)
        }
    }
    
    func reset() {
        chatHistory.removeAll()
    }
}
