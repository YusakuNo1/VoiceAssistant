import UIKit
import AVFoundation
import MicrosoftCognitiveServicesSpeech


class ViewController: UIViewController {
    private var audioManager: AudioManager!
    private var apiManager: ApiManager!
    private var chatTable = ChatTable()
    private let mediaManager = MediaManager()

    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var mainActionButton: UIButton!
    @IBOutlet weak var testActionButton: UIButton!
    @IBOutlet weak var photoActionButtonItem: UIBarButtonItem!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressLabelContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let apiManager = ApiManager(appendChatMessages: self.appendChatMessages)
        self.apiManager = apiManager
        self.audioManager = AudioManager(apiManager: apiManager, updateProgress: self.updateProgress)
        self.updateProgress(.Idle)
        self.chatTableView.dataSource = self.chatTable
        self.chatTableView.delegate = self.chatTable
    }

    @IBAction func onMainActionButtonClicked(_ sender: Any) {
        self.updateProgress(.Init)
        Task {
            await self.audioManager.recognizeFromMic()
        }
    }

    @IBAction func onUploadActionButtonClicked(_ sender: Any) {
        self.mediaManager.showOption(vc: self)
    }

    @IBAction func onPhotoActionButtonClicked(_ sender: Any) {
    }

    @IBAction func onResetActionButtonClicked(_ sender: Any) {
        self.chatTable.reset()
        self.chatTableView.reloadData()
        self.apiManager.resetChatId()
    }

    @IBAction func onTestActionButtonClicked(_ sender: Any) {
        // Test
    }

    private func updateProgress(_ progressState: ProgressState) {
        DispatchQueue.main.async {
            switch progressState {
            case ProgressState.Idle:
                self.progressLabelContainer.isHidden = true
                self.mainActionButton.isEnabled = true
                self.mainActionButton.titleLabel?.text = "  Start  "
            case ProgressState.Init:
                self.progressLabelContainer.isHidden = false
                self.progressLabel.text = "Initializing..."
                self.mainActionButton.isEnabled = false
                self.mainActionButton.titleLabel?.text = "..."
            case ProgressState.Listen:
                self.progressLabelContainer.isHidden = false
                self.progressLabel.text = "Listening..."
                self.mainActionButton.isEnabled = true
                self.mainActionButton.titleLabel?.text = "Cancel"
            case ProgressState.WaitForRes:
                self.progressLabelContainer.isHidden = false
                self.progressLabel.text = "Waiting for response..."
                self.mainActionButton.isEnabled = true
                self.mainActionButton.titleLabel?.text = "Cancel"
            case ProgressState.Speak:
                self.progressLabelContainer.isHidden = true
                self.mainActionButton.isEnabled = true
                self.mainActionButton.titleLabel?.text = "Cancel"
            }
        }
    }

    private func appendChatMessages(_ chatId: String, _ messages: [Message]) {
        self.chatTable.appendChatMessages(chatId, messages)
        self.chatTableView.reloadData()
    }
}
