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
        
        // TODO: this line only get the text content for now
        for content in chatHistory[indexPath.row].content {
            if content.type != .text {
                continue
            }
            
            cell.contentLabel.text = content.text ?? ""
        }
        return cell
    }
    
    func appendChatMessages(_ chatId: String, _ messages: [Message]) {
        if chatId != self.chatId {
            self.chatId = chatId
            self.chatHistory.removeAll()
        }

        for message in messages {
            chatHistory.append(message)
        }
    }
    
    func reset() {
        chatHistory.removeAll()
    }
}
