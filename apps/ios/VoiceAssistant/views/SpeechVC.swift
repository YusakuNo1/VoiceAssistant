import UIKit
import AVFoundation
import MicrosoftCognitiveServicesSpeech


let BUTTON_ICON_SIZE = 40.0

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
        if let imageView = self.startStopButton.imageView {
            imageView.image = UIImage(named: "IconStart")
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: BUTTON_ICON_SIZE).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: BUTTON_ICON_SIZE).isActive = true
        }
    }
}
