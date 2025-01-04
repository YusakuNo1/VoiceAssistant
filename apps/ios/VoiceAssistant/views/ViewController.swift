import UIKit
import AVFoundation
import MicrosoftCognitiveServicesSpeech


class ViewController: UIViewController {
    private var speechManager: AbstractSpeechManager!
    private var apiManager: ApiManager!
    private var mediaManager: MediaManager!
    private var chatTable: ChatTable!
    
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var mainActionButton: UIButton!
    @IBOutlet weak var testActionButton: UIButton!
    @IBOutlet weak var photoActionButtonItem: UIBarButtonItem!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressLabelContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Chat"
        
        self.chatTable = ChatTable(parentVC: self)
        
        let apiManager = ApiManager(appendChatMessages: self.appendChatMessages)
        self.apiManager = apiManager
//        self.speechManager = LocalSpeechManager(apiManager: apiManager, updateProgress: self.updateProgress)
        self.speechManager = RemoteSpeechManager(apiManager: apiManager, updateProgress: self.updateProgress)
        self.mediaManager = MediaManager()
        self.mediaManager.registerUpdatedListener(listener: self.mediaManagerUpdated)
        
        self.updateProgress(.Idle)
        self.chatTableView.dataSource = self.chatTable
        self.chatTableView.delegate = self.chatTable
    }
    
    @IBAction func onMainActionButtonClicked(_ sender: Any) {
        self.updateProgress(.Init)
        Task {
            let imageList = self.mediaManager.imageList
            self.speechManager.recognize(imageList: imageList)
            mediaManager.resetImageList()
        }
    }
    
    @IBAction func onUploadActionButtonClicked(_ sender: Any) {
        self.mediaManager.showOption(vc: self)
    }
    
    @IBAction func onPhotoActionButtonClicked(_ sender: Any) {
    }

    @IBAction func onResetActionButtonClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Do you want to reset?", message: "All chat messages will be deleted.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { _ in
            self.chatTable.reset()
            self.chatTableView.reloadData()
            self.apiManager.resetChatId()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onTestActionButtonClicked(_ sender: Any) {
        print("test button clicked")
    }
    
    @IBAction func onStartSpeechRecognition(_ sender: Any) {
        let imageList = self.mediaManager.imageList
        self.speechManager.recognize(imageList: imageList)
    }

    @IBAction func onStopSpeechRecognition(_ sender: Any) {
        let imageList = self.mediaManager.imageList
        self.speechManager.stopSpeechRecognize(imageList: imageList)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show-textdrawingvc" {
            let vc = segue.destination as! TextDrawingVC
            vc.mediaManager = self.mediaManager
        } else if segue.identifier == "show-imagegalleryvc" {
            let vc = segue.destination as! ImageGalleryVC
            var uiImageList: [UIImage] = []
            for image in self.mediaManager.imageList {
                if let uiImage = ImageUtils.imageToUIImage(image: image) {
                    uiImageList.append(uiImage)
                }
            }
            vc.uiImageList = uiImageList
        } else if segue.identifier == "show-imagegalleryvc-from-cell" {
            let vc = segue.destination as! ImageGalleryVC
            let uiImageList = sender as! [UIImage]
            vc.uiImageList = uiImageList
        }
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
    
    private func appendChatMessages(_ chatId: String?, _ messages: [Message]) {
        DispatchQueue.main.async {
            self.chatTable.appendChatMessages(chatId, messages)
            self.chatTableView.reloadData()
        }
    }
    
    private func mediaManagerUpdated(_ imageList: [Image]) {
        self.photoActionButtonItem.isHidden = imageList.isEmpty
    }
}
