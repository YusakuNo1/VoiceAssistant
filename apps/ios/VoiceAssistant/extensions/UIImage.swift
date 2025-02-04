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
        case .jpeg: newImage.jpegData(compressionQuality: IMAGE_JPEG_QUALITY)!
        case .png: newImage.pngData()!
        }
        return Image(width: size, height: size, format: format, data: data)
    }
}
