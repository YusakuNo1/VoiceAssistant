import UIKit

enum CellId: String {
    case user = "cell-user"
    case assistant = "cell-assistant"
}

class ChatTable: NSObject, UITableViewDelegate, UITableViewDataSource {
    private var parentVC: UIViewController
    
    init(parentVC: UIViewController) {
        self.parentVC = parentVC
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ChatHistoryManager.shared.getChatHistory().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create cells from story board, for roles of "user", create with ID "cell-user", otherwise, create with ID "cell-assistant"
        guard let message = ChatHistoryManager.shared.getChatMessage(index: indexPath.row) else {
            return UITableViewCell()
        }
        
        let identifier = message.role == Role.user ? CellId.user.rawValue : CellId.assistant.rawValue
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ChatTableCell else {
            return UITableViewCell()
        }
        
        cell.contentLabelContainer.layer.cornerRadius = 10
        cell.contentLabelContainer.layer.borderWidth = 2
        cell.contentLabelContainer.layer.backgroundColor = UIColor.yellow.cgColor
        cell.contentLabelContainer.layer.borderColor = UIColor.lightGray.cgColor
        cell.contentLabelContainer.layer.masksToBounds = true
        
        // Assumption: only 1 "text" type
        var imageContentList: [MessageContent] = []
        for content in message.content {
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
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let messageContent = ChatHistoryManager.shared.getChatMessage(index: indexPath.row)?.content else { return }

        var uiImageList: [UIImage] = []
        for item in messageContent {
            if item.type == .image_url, let imageUrl = item.image_url?.url, let uiImage = ImageUtils.imageFromDataUrl(dataUrl: imageUrl) {
                uiImageList.append(uiImage)
            }
        }
        self.parentVC.performSegue(withIdentifier: "show-textdrawingvc", sender: uiImageList)
    }
}
