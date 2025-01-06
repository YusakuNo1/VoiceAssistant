import UIKit
import AVFoundation
import MicrosoftCognitiveServicesSpeech

let BUTTON_ICON_SIZE = 40.0

enum ButtonImageName: String {
    case start = "IconStart"
    case stop = "IconStop"
    case reset = "IconReset"
    case attachment = "IconAttachment"
    case attach = "IconAttach"
    case settings = "IconSettings"
}

let StatusImageNameMap: [ProgressState: String] = [
    ProgressState.Idle: "IconStatusIdle",
    ProgressState.Init: "",
    ProgressState.Listen: "IconStatusListening",
    ProgressState.WaitForRes: "",
    ProgressState.Speak: "IconStatusSpeaking",
]

class SpeechVC: UIViewController {
    @IBOutlet weak var statusActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var attachButton: UIButton!
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        self._updateProgress(.Idle)
        self._chatHistoryUpdated()
        self._setupButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SpeechManager.shared.speech.updateProgress = self._updateProgress
        MediaManager.shared.registerUpdatedListener(key: String(describing: self), listener: self._mediaManagerUpdated)
        ChatHistoryManager.shared.registerChatHistoryUpdateListener(listenerKey: String(describing: self), listener: self._chatHistoryUpdated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MediaManager.shared.unregisterUpdatedListener(key: String(describing: self))
        ChatHistoryManager.shared.unregisterChatHistoryUpdateListener(listenerKey: String(describing: self))
    }
    
    @IBAction func onStartStopButtonClicked(_ sender: Any) {
        self._updateProgress(.Init)
        Task {
            SpeechManager.shared.recognize()
            MediaManager.shared.resetImageList()
        }
    }

    @IBAction func onResetButtonClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Do you want to reset?", message: "All chat messages will be deleted.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { _ in
            ChatHistoryManager.shared.clearChatHistory()
        }))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func onAttachmentButtonClicked(_ sender: Any) {
    }

    @IBAction func onAttachButtonClicked(_ sender: Any) {
        MediaManager.shared.showOption(vc: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show-imagegalleryvc" {
            let vc = segue.destination as! ImageGalleryVC
            var uiImageList: [UIImage] = []
            for image in MediaManager.shared.imageList {
                if let uiImage = ImageUtils.imageToUIImage(image: image) {
                    uiImageList.append(uiImage)
                }
            }
            vc.uiImageList = uiImageList
        }
    }

    private func _setupButtons() {
        self._setupButton(button: self.startStopButton, imageName: .start)
        self._setupButton(button: self.resetButton, imageName: .reset)
        self._setupButton(button: self.attachButton, imageName: .attach)
        self._setupButton(button: self.attachmentButton, imageName: .attachment)
        self._setupButton(button: self.settingsButton, imageName: .settings)
    }
    
    private func _setupButton(button: UIButton, imageName: ButtonImageName) {
        if let imageView = button.imageView, let image = UIImage(named: imageName.rawValue) {
            button.titleLabel?.text = ""
            button.setImage(image, for: .normal)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: BUTTON_ICON_SIZE).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: BUTTON_ICON_SIZE).isActive = true
        }
    }
    
    private func _updateProgress(_ progressState: ProgressState) {
        DispatchQueue.main.async {
            if progressState == ProgressState.Init || progressState == ProgressState.WaitForRes {
                self.statusImageView.isHidden = true
                self.statusActivityIndicator.isHidden = false
            } else {
                self.statusImageView.isHidden = false
                self.statusActivityIndicator.isHidden = true
                let imageName = StatusImageNameMap[progressState]!
                let image = UIImage(named: imageName)
                self.statusImageView.image = image
            }
        }
    }

    private func _chatHistoryUpdated() {
        DispatchQueue.main.async {
            let chatHistory = ChatHistoryManager.shared.getChatHistory()
            self.resetButton.isHidden = chatHistory.isEmpty
        }
    }

    private func _mediaManagerUpdated(_ imageList: [Image]) {
        self.attachmentButton.isHidden = imageList.isEmpty
    }
}
