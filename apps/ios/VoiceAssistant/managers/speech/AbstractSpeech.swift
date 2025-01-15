import AVFoundation
import MapKit


class AbstractSpeech: NSObject {
    internal let _busId: AVAudioNodeBus = 0
    internal let _sampleRate = 16000
    internal let _bufferSize = 2048
    internal var _audioPlayerVolume: Float = 1.0
    
    internal let _audioEngine: AVAudioEngine = AVAudioEngine()
    
    internal var _updateProgress: ((ProgressState) -> Void)?
    var updateProgress: ((ProgressState) -> Void)? {
        get { _updateProgress }
        set { _updateProgress = newValue }
    }
    
    override init() {}
    
    func recognize(imageList: [Image]) {
        fatalError( "recognize() must be implemented by subclasses")
    }
    
    func synthesize(text: String) {
        fatalError( "synthesize() must be implemented by subclasses")
    }
    
    internal func _setAudioMode(mode: AudioMode) {
        do {
            if mode == AudioMode.Playback {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            } else if mode == AudioMode.Record {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord, with: .mixWithOthers)
            }
            
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio mode: \(error.localizedDescription)")
        }
    }
    
    internal func _onSpeechRecognized(message: String, imageList: [Image]) {
        self._updateProgress?(.WaitForRes)
        ApiManager.shared.sendChatMessages(message: message, imageList: imageList) { (result) -> Void in
            switch result {
            case .success(let responseString):
                self._onSpeechRecognizedSuccess(responseString: responseString)
            case .failure(let error):
                print("Error sending message: \(error)")
            }
        }
    }
    
    internal func _onSpeechRecognizedSuccess(responseString: String) {
        do {
            var actions: [Action] = []

            let lines = responseString.split(separator: "\n")
            for line in lines {
                let jsonDecoder = JSONDecoder()
                let lineData = line.data(using: .utf8)!
                let action = try jsonDecoder.decode(Action.self, from: lineData)
                actions.append(action)
            }
            self._onSpeechRecognizedSuccessAction(actions: actions)
        } catch {
            self.synthesize(text: responseString)
        }
    }
    
    internal func _onSpeechRecognizedSuccessAction(actions: [Action]) {
        for action in actions {
            if action.actionType == ActionType.changeVolume {
                if let volumeRaw = action.data["volume"] {
                    switch volumeRaw {
                    case .double(let volume):
                        if volume >= 0 && volume <= 100 {
                            self._audioPlayerVolume = Float(volume) / 100
                            self.synthesize(text: ACTION_SUCCESS_MESSAGE)
                        } else {
                            self.synthesize(text: ACTION_FAILURE_MESSAGE_CHANGE_VOLUME)
                        }
                    case .string(let volumeString):
                        Logger.log(.error, "Unsupported volume format: \(volumeString)")
                        self.synthesize(text: ACTION_FAILURE_MESSAGE_CHANGE_VOLUME)
                    }
                }
            } else if action.actionType == ActionType.openMap {
                var latitude: Double = 0
                var longitude: Double = 0
                if let latitudeRaw = action.data["latitude"], let longitudeRaw = action.data["longitude"] {
                    switch latitudeRaw {
                    case .double(let latitudeValue):
                        latitude = latitudeValue
                    case .string(let latitudeString):
                        latitude = Double(latitudeString)!
                    }
                    
                    switch longitudeRaw {
                    case .double(let longitudeValue):
                        longitude = longitudeValue
                    case .string(let longitudeString):
                        longitude = Double(longitudeString)!
                    }

                    self.synthesize(text: ACTION_SUCCESS_MESSAGE)

                    let regionDistance: CLLocationDistance = 10000
                    let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
                    let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
                    let options = [
                        MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                        MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
                    ]
                    let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.openInMaps(launchOptions: options)
                }
            }
        }
    }
}
