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

    private var _updatedListeners: [String: (([Image]) -> Void)] = [:]
    func registerUpdatedListener(key: String, listener: @escaping ([Image]) -> Void) {
        self._updatedListeners[key] = listener
    }
    func unregisterUpdatedListener(key: String) {
        self._updatedListeners.removeValue(forKey: key)
    }
    
    func dispatchUpdateEvent() {
        DispatchQueue.main.async {
            self._updatedListeners.values.forEach { (listener) in
                listener(self._imageList)
            }
        }
    }
    
    func showOption(vc: UIViewController) {
        let alertController = UIAlertController(title: "Select Image", message: "Choose an option", preferredStyle: .actionSheet)
        let photoLibraryAction = UIAlertAction(title: "From Photo Library", style: .default) { _ in
            self.openImagePicker(vc, .photoLibrary)
        }
        let cameraAction = UIAlertAction(title: "From Camera", style: .default) { _ in
            self.openImagePicker(vc, .camera)
        }
        let drawAction = UIAlertAction(title: "Draw Text", style: .default) { _ in
            self.showTextDrawingVC(vc)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(photoLibraryAction)
        alertController.addAction(cameraAction)
        alertController.addAction(drawAction)
        alertController.addAction(cancelAction)
        vc.present(alertController, animated: true, completion: nil)
    }
    
    func setImageList(_ imageList: [Image]) {
        _imageList = imageList
        dispatchUpdateEvent()
    }

    private func showTextDrawingVC(_ vc: UIViewController) {
        vc.performSegue(withIdentifier: "show-textdrawingvc", sender: vc)
    }

    private func openImagePicker(_ vc: UIViewController, _ mediaSourceType: MediaSourceType) {
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
