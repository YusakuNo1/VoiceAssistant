import UIKit

extension UIImage {
    func toSquareImage(format: ImageFormat = .jpeg, size: CGFloat) -> Image? {
//        guard let newImage = ImageUtils.cropImageToSquare(image: self, size: size) else {
//            return nil
//        }
        guard let newImage = ImageUtils.resizeImage(image: self, size: size) else {
            return nil
        }
        let data = switch format {
        case .jpeg: UIImageJPEGRepresentation(newImage, IMAGE_JPEG_QUALITY)!
        case .png: UIImagePNGRepresentation(newImage)!
        }
        return Image(width: size, height: size, format: format, data: data)
    }
}
