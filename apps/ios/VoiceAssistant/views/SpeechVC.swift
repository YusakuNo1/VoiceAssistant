import UIKit
import AVFoundation
import MicrosoftCognitiveServicesSpeech

let BUTTON_ICON_SIZE = 40.0

enum ButtonImageName: String {
    case start = "IconStart"
    case stop = "IconStop"
    case reset = "IconReset"
    case attachment = "IconAttachment"
    case settings = "IconSettings"
}

class SpeechVC: UIViewController {
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self._setupButtons()
    }

    @IBAction func onStartStopButtonClicked(_ sender: Any) {
    }
    
    @IBAction func onResetButtonClicked(_ sender: Any) {
    }
    
    @IBAction func onAttachmentButtonClicked(_ sender: Any) {
    }
    
    @IBAction func onSettingsuttonClicked(_ sender: Any) {
    }
    
    private func _setupButtons() {
        self._setupButton(button: self.startStopButton, imageName: ButtonImageName.start)
        self._setupButton(button: self.resetButton, imageName: ButtonImageName.reset)
        self._setupButton(button: self.attachmentButton, imageName: ButtonImageName.attachment)
        self._setupButton(button: self.settingsButton, imageName: ButtonImageName.settings)
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
}
