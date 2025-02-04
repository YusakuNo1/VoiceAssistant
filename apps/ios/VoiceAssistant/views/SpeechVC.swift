import AVFoundation
import Combine
import MicrosoftCognitiveServicesSpeech
import UIKit

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
    private var cancellable: AnyCancellable?

    @IBOutlet weak var statusActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var attachButton: UIButton!
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self._updateProgress(.Idle)
        self._chatHistoryUpdated()
        self._mediaManagerUpdated()
        self._setupButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        SpeechManager.shared.speech.updateProgress = self._updateProgress
        MediaManager.shared.registerUpdatedListener(key: String(describing: self), listener: self._mediaManagerUpdated)
        ChatHistoryManager.shared.registerChatHistoryUpdateListener(listenerKey: String(describing: self), listener: self._chatHistoryUpdated)

        self.cancellable = EventManager.shared.eventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                
                switch event {
                case .showImages(let imageDataUrls):
                    var uiImageList: [UIImage] = []
                    for dataUrl in imageDataUrls {
                        if let uiImage = ImageUtils.imageFromDataUrl(dataUrl: dataUrl) {
                            uiImageList.append(uiImage)
                        }
                    }
                    
                    if !uiImageList.isEmpty {
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "show-imagegalleryvc-from-event", sender: uiImageList)
                        }
                    }
                    return
                }
            }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MediaManager.shared.unregisterUpdatedListener(key: String(describing: self))
        ChatHistoryManager.shared.unregisterChatHistoryUpdateListener(listenerKey: String(describing: self))
        self.cancellable?.cancel()
    }

    @IBAction func onTestButtonClicked(_ sender: Any) {
//        let query = "Where is microsoft headquarter?"
        let query = "what is the weather in redmond"
        let messages = [Message(role: .user, content: [MessageContent(text: query)])]
        LocalLlmManager.shared.sendChatMessages(messages: messages) { result in
            print("result: \(result)")
        }
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
            MediaManager.shared.resetImageList()
        }))
        self.present(alert, animated: true, completion: nil)
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
        } else if segue.identifier == "show-imagegalleryvc-from-event", let uiImageList = sender as? [UIImage] {
            let vc = segue.destination as! ImageGalleryVC
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
            Logger.log(message: "progressState: \(progressState)")

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

    private func _mediaManagerUpdated() {
        let imageList = MediaManager.shared.imageList
        self.attachmentButton.isHidden = imageList.isEmpty
    }
}
