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
                try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            } else if mode == AudioMode.Record {
                try AVAudioSession.sharedInstance().setCategory(.record, options: .mixWithOthers)
            }
            
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio mode: \(error.localizedDescription)")
        }
    }

    internal func _onSpeechRecognized(message: String, imageList: [Image]) {
        self._updateProgress?(.WaitForRes)
        let messages = MessageUtils.buildMessages(message: message, imageList: imageList)
        ChatHistoryManager.shared.appendChatMessages(messages: messages)
        
//        ApiManager.shared.sendChatMessages(messages: messages) { (result) -> Void in
//            switch result {
//            case .success(let responseString):
//                self._onSpeechRecognizedSuccess(responseString: responseString)
//            case .failure(let error):
//                print("Error sending message: \(error)")
//            }
//        }

        LocalLlmManager.shared.sendChatMessages(messages: messages) { (result) -> Void in
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

            let messages: [Message] = self._onSpeechRecognizedSuccessAction(actions: actions)
            ChatHistoryManager.shared.appendChatMessages(messages: messages)
        } catch {
            self.synthesize(text: responseString)
            ChatHistoryManager.shared.appendChatMessages(messages: [
                Message(role: Role.assistant, content: [MessageContent(text: responseString)])
            ])
        }
    }
    
    internal func _onSpeechRecognizedSuccessAction(actions: [Action]) -> [Message] {
        var messages: [Message] = []

        for action in actions {
            if action.actionType == ActionType.changeVolume {
                if let volumeRaw = action.data["volume"] {
                    switch volumeRaw {
                    case .double(let volume):
                        if volume >= 0 && volume <= 100 {
                            self._audioPlayerVolume = Float(volume) / 100
                            let text = String(format: ACTION_SUCCESS_MESSAGE_CHANGE_VOLUME_TEMPLATE, Int(volume))
                            self.synthesize(text: text)
                            messages.append(Message(role: Role.assistant, content: [MessageContent(text: text)]))
                        } else {
                            self.synthesize(text: ACTION_FAILURE_MESSAGE_CHANGE_VOLUME)
                        }
                    case .string(let volumeString):
                        Logger.log(.error, "Unsupported volume format: \(volumeString)")
                        self.synthesize(text: ACTION_FAILURE_MESSAGE_CHANGE_VOLUME)
                    }
                }
            } else if action.actionType == ActionType.openMap {
                var name = ""
                var latitude: Double = 0
                var longitude: Double = 0
                if let nameRaw = action.data["name"], let latitudeRaw = action.data["latitude"], let longitudeRaw = action.data["longitude"] {
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
                    
                    switch nameRaw {
                    case .string(let nameValue):
                        name = nameValue
                    case .double(_):
                        name = ""
                    }

                    let text = String(format: ACTION_SUCCESS_MESSAGE_OPEN_MAP_TEMPLATE, name)
                    self.synthesize(text: text)
                    
                    // Delay for 1 second, and then run the code in the block
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        let regionDistance: CLLocationDistance = 10000
                        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
                        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
                        let options = [
                            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
                        ]
                        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                        let mapItem = MKMapItem(placemark: placemark)
                        mapItem.openInMaps(launchOptions: options)
                    }
                    messages.append(Message(role: Role.assistant, content: [MessageContent(text: text)]))
                }
            } else if action.actionType == ActionType.getWeather {
                if let nameRaw = action.data["name"], let tempFRaw = action.data["temp_f"] {
                    var name: String = ""
                    var tempF: Double = 0

                    switch nameRaw {
                    case .string(let nameValue):
                        name = nameValue
                    case .double(_):
                        name = ""
                    }
                    
                    switch tempFRaw {
                    case .double(let tempFValue):
                        tempF = tempFValue
                    case .string(_):
                        tempF = 0
                    }
                    let text = String(format: ACTION_SUCCESS_MESSAGE_GET_WEATHER_FAHRENHEIT_TEMPLATE, name, tempF)
                    self.synthesize(text: text)
                    messages.append(Message(role: Role.assistant, content: [MessageContent(text: text)]))
                }
            } else if action.actionType == ActionType.openBrowser {
                if let nameRaw = action.data["name"], let urlRaw = action.data["url"] {
                    var name = ""
                    var url = ""

                    switch nameRaw {
                    case .string(let nameValue):
                        name = nameValue
                    case .double(_):
                        name = ""
                    }

                    switch urlRaw {
                    case .string(let urlValue):
                        url = urlValue
                    case .double(_):
                        url = ""
                    }

                    let text = String(format: ACTION_SUCCESS_MESSAGE_OPEN_BROWSER_TEMPLATE, url)
                    self.synthesize(text: text)
                    messages.append(Message(role: Role.assistant, content: [MessageContent(text: text)]))
                    // Delay for 1 second, and then run the code in the block
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if let urlString = URL(string: url), UIApplication.shared.canOpenURL(urlString) {
                            UIApplication.shared.open(urlString, options: [:], completionHandler: { (success) in
                                if success {
                                    print("Browser opened successfully")
                                } else {
                                    print("Failed to open browser")
                                    self.synthesize(text: ACTION_FAILURE_MESSAGE_OPEN_BROWSER)
                                }
                            })
                        } else {
                            self.synthesize(text: ACTION_FAILURE_MESSAGE_OPEN_BROWSER)
                        }
                    }
                }
            } else if action.actionType == ActionType.findImage {
                if let queryRaw = action.data["query"], let imageDataUrlRaw = action.data["image_data_url"] {
                    var query = ""
                    var imageDataUrl = ""
                    
                    switch queryRaw {
                    case .string(let queryValue):
                        query = queryValue
                    case .double(_):
                        query = ""
                    }

                    switch imageDataUrlRaw {
                    case .string(let imageDataUrlValue):
                        imageDataUrl = imageDataUrlValue
                    case .double(_):
                        imageDataUrl = ""
                    }
                    
                    let text = String(format: ACTION_SUCCESS_MESSAGE_FIND_IMAGE_TEMPLATE, query)
                    var message = Message(role: Role.assistant, content: [
                        MessageContent(text: text)
                    ])
                    message.content.append(MessageContent(image_url: imageDataUrl))
                    messages.append(message)
                    self.synthesize(text: text)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        EventManager.shared.eventPublisher.send(.showImages(imageDataUrls: [imageDataUrl]))
                    }
                } else {
                    self.synthesize(text: ACTION_FAILURE_MESSAGE_FIND_IMAGE)
                }
            }
        }
        
        return messages
    }
}
