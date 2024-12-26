import UIKit
import PhotosUI


enum MediaSourceType {
    case photoLibrary
    case camera
}

class MediaManager: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    private var imageList: [Image] = []
    
    func showOption(vc: ViewController) {
        let alertController = UIAlertController(title: "Select Image", message: "Choose an option", preferredStyle: .actionSheet)
        let photoLibraryAction = UIAlertAction(title: "From Photo Library", style: .default) { _ in
            self.openImagePicker(vc, .photoLibrary)
        }
        let cameraAction = UIAlertAction(title: "From Camera", style: .default) { _ in
            self.openImagePicker(vc, .camera)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(photoLibraryAction)
        alertController.addAction(cameraAction)
        alertController.addAction(cancelAction)
        vc.present(alertController, animated: true, completion: nil)
    }
    
    private func openImagePicker(_ vc: ViewController, _ mediaSourceType: MediaSourceType) {
        if mediaSourceType == .photoLibrary {
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = 1
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            vc.present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.allowsEditing = true
            picker.delegate = self
            vc.present(picker, animated: true)
        }
    }
    
    // MARK: - PHPickerViewControllerDelegate methods

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider else { return }
        
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
//                    self.selectedImageView.image = image as? UIImage
                }
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate methods

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info["UIImagePickerControllerEditedImage"] as? UIImage ?? info["UIImagePickerControllerOriginalImage"] as? UIImage {
            print("Image: \(image)")
        }

        picker.dismiss(animated: true)

    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
