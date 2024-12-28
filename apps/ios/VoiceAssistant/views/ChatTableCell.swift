import UIKit

class ChatTableCell: UITableViewCell {    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var contentLabelContainer: UIView!
    @IBOutlet weak var thumbnailContainerHeight: NSLayoutConstraint!
    @IBOutlet var thumbnails: [UIImageView]!
}
