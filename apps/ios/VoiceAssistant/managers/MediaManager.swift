import UIKit


enum MediaSourceType {
    case photoLibrary
    case camera
}

class MediaManager: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var _imageList: [Image] = []
    var imageList: [Image] {
        get {
            return _imageList
        }
    }

    func resetImageList() {
        self._imageList.removeAll()
        self.dispatchUpdateEvent()
    }

    private var updatedListener: [(([Image]) -> Void)] = []
    func registerUpdatedListener(listener: @escaping ([Image]) -> Void) {
        updatedListener.append(listener)
    }
    
    func dispatchUpdateEvent() {
        DispatchQueue.main.async {
            self.updatedListener.forEach { (listener) in
                listener(self._imageList)
            }
        }
    }
    
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
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.allowsEditing = true
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

    // MARK: - UIImagePickerControllerDelegate methods

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self._imageList.removeAll()
        let uiImage = info["UIImagePickerControllerEditedImage"] as? UIImage ?? info["UIImagePickerControllerOriginalImage"] as? UIImage
        if let uiImage = uiImage, let image = uiImage.toSquareImage(format: .jpeg, size: IMAGE_SIZE) {
            self._imageList.append(image)
        } else {
            Logger.log(.error, "Error converting UIImage to Image")
        }
        self.dispatchUpdateEvent()
        picker.dismiss(animated: true)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
