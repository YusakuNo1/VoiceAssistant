import UIKit

class ImageGalleryVC: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    private var _uiImageList: [UIImage] = []
    var uiImageList: [UIImage] {
        get { return _uiImageList }
        set { _uiImageList = newValue }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Images"        
        imageView.image = self.uiImageList.first
    }
}
