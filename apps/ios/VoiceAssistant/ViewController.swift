import UIKit
import AVFoundation
import MicrosoftCognitiveServicesSpeech


class ViewController: UIViewController {
    var label: UILabel!
    var fromMicButton: UIButton!
    var testButton: UIButton!
    var audioManager: AudioManager!
    var _apiManager: ApiManager!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let apiManager = ApiManager()
        self._apiManager = apiManager
        self.audioManager = AudioManager(apiManager: apiManager, updateLabel: self.updateLabel)
        
        label = UILabel(frame: CGRect(x: 100, y: 100, width: 200, height: 200))
        label.textColor = UIColor.black
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.text = "Recognition Result"
        
        fromMicButton = UIButton(frame: CGRect(x: 100, y: 400, width: 200, height: 50))
        fromMicButton.setTitle("Recognize", for: .normal)
        fromMicButton.addTarget(self, action:#selector(self.fromMicButtonClicked), for: .touchUpInside)
        fromMicButton.setTitleColor(UIColor.black, for: .normal)
        
        testButton = UIButton(frame: CGRect(x: 100, y: 500, width: 200, height: 50))
        testButton.setTitle("Play", for: .normal)
        testButton.addTarget(self, action:#selector(self.testButtonClicked), for: .touchUpInside)
        testButton.setTitleColor(UIColor.black, for: .normal)

        self.view.addSubview(label)
        self.view.addSubview(fromMicButton)
        self.view.addSubview(testButton)
    }
    
    @objc func fromMicButtonClicked() {
        DispatchQueue.global(qos: .userInitiated).async {
            Task {
                await self.audioManager.recognizeFromMic()
            }
        }
    }
    
    @objc func testButtonClicked() {
        DispatchQueue.global(qos: .userInitiated).async {
            Task {
                await self.audioManager.synthesize(inputText: "where is redmond?")
            }
        }
    }
    
    func updateLabel(text: String?, color: UIColor) {
        DispatchQueue.main.async {
            self.label.text = text
            self.label.textColor = color
        }
    }
}
