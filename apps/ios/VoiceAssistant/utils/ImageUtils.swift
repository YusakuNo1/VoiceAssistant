import UIKit

class ImageUtils {
    // TODO: this function only scales width currently
    static func resizeImage(image: UIImage, size: CGFloat) -> UIImage? {
        let scale = size / image.size.width
        let height = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(size, height))
        image.draw(in: CGRectMake(0, 0, size, height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
//    // This function not working as a lot of UIImage doesn't include ciImage
//    static func cropImageToSquare(image: UIImage, size: CGFloat) -> UIImage? {
//        let isPortrait = image.size.width < image.size.height
//        let scale: CGFloat = isPortrait ? size / image.size.width : size / image.size.height
//        let width = image.size.width * scale
//        let height = image.size.height * scale
//        UIGraphicsBeginImageContext(CGSizeMake(width, height))
//        image.draw(in: CGRectMake(0, 0, width, height))
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        guard let newImage = newImage else {
//            return nil
//        }
//
//        let xOffset: CGFloat = isPortrait ? 0 : (width - size) / 2
//        let yOffset: CGFloat = isPortrait ? (height - size) / 2 : 0
//        let tmp = newImage.ciImage?.cropped(to: CGRect(x: xOffset, y: yOffset, width: size, height: size))
//        guard let newImage = tmp else {
//            return nil
//        }
//
//        return UIImage(ciImage: newImage)
//    }
    
    static func imageFromDataUrl(dataUrl: String) -> UIImage? {
        guard let url = URL(string: dataUrl) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        let image = UIImage(data: data)
        return image
    }
    
    static func imageToUIImage(image: Image?) -> UIImage? {
        guard let image = image, let uiImage = UIImage(data: image.data) else { return nil }
        return uiImage
    }
}
