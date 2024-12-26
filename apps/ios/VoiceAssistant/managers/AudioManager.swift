import UIKit
import AVFoundation

class AudioManager {
    var credentials: Credentials?
    var sampleRate = 16000
    var bufferSize = 2048
    var audioEngine: AVAudioEngine = AVAudioEngine()
    var conversionQueue = DispatchQueue(label: "conversionQueue")
    
    var speechConfig: SPXSpeechConfiguration!
    var audioConfig: SPXAudioConfiguration!
    var reco: SPXSpeechRecognizer!
    var pushStream: SPXPushAudioInputStream!

    let apiManager: ApiManager!
    let updateProgress: (ProgressState) -> Void
    
    public init(apiManager: ApiManager, updateProgress: @escaping (ProgressState) -> Void) {
        self.apiManager = apiManager
        self.updateProgress = updateProgress
    }
    
    func recognizeFromMic(imageList: [Image]) async {
        self._setAudioMode(mode: .Record)

        self.apiManager.getCredentials() { result in
            switch result {
                case .success(let credentials):
                    try! self.speechConfig = SPXSpeechConfiguration(subscription: credentials.speech.key, region: credentials.speech.region)
                    self.speechConfig?.speechRecognitionLanguage = "en-US"
                    
                    self.pushStream = SPXPushAudioInputStream()
                    self.audioConfig = SPXAudioConfiguration(streamInput: self.pushStream)
                    self.reco = try! SPXSpeechRecognizer(speechConfiguration: self.speechConfig!, audioConfiguration: self.audioConfig!)

                    self.reco.addRecognizedEventHandler() {reco, evt in
                        print("Final recognition result: \(evt.result.text ?? "(no result)")")
                        //            self.updateLabel(text: evt.result.text, color: .gray)
                        
                        if let message = evt.result.text {
                            self.updateProgress(.WaitForRes)
                            self.apiManager.sendChatMessages(message: message, imageList: imageList) { (result) -> Void in
                                switch result {
                                case .success(let respnoseString):
//                                    print("LLM Response: \(respnoseString)")
                                    Task {
                                        await self.synthesize(inputText: respnoseString)
                                    }
                                case .failure(let error):
                                    print("Error sending message: \(error)")
                                }
                            }
                        }
                    }
                    
                    self.reco.addCanceledEventHandler { reco, evt in
                        print("Recognition canceled: \(evt.errorDetails?.description ?? "(no result)")")
                        self.updateProgress(.Idle)
                    }
                    
                    try! self.reco.recognizeOnceAsync({ srresult in
                        self.audioEngine.stop()
                        self.audioEngine.inputNode.removeTap(onBus: 0)
                        self.pushStream.close()
                    })
                    self._readDataFromMicrophone()
                    self.updateProgress(.Listen)
                case .failure(let error):
                    print("Error: \(error)")
            }
        }
    }
    
    func synthesize(inputText: String) async {
        self._setAudioMode(mode: .Playback)
        self.updateProgress(.Speak)

        self.apiManager.getCredentials() { result in
            switch result {
            case .success(let credentials):
                var speechConfig: SPXSpeechConfiguration?
                do {
                    try speechConfig = SPXSpeechConfiguration(subscription: credentials.speech.key, region: credentials.speech.region)
                } catch {
                    print("error \(error) happened")
                    speechConfig = nil
                }
                
                speechConfig?.speechSynthesisVoiceName = "en-US-AvaMultilingualNeural";
                
                let synthesizer = try! SPXSpeechSynthesizer(speechConfig!)
                
                let result = try! synthesizer.speakText(inputText)
                if result.reason == SPXResultReason.canceled
                {
                    do {
                        let cancellationDetails = try SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: result)
                        print("cancelled, error code: \(cancellationDetails.errorCode) detail: \(cancellationDetails.errorDetails!) ")
                        print("Did you set the speech resource key and region values?");
                    } catch {
                        print(error)
                    }
                }
                self.updateProgress(.Idle)
            case .failure(let error):
                print("error \(error) happened")
                self.updateProgress(.Idle)
            }
        }
    }

        
    private func _setAudioMode(mode: AudioMode) {
        do {
            if mode == AudioMode.Playback {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            } else if mode == AudioMode.Record {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord, with: .mixWithOthers)
            }
            
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
    }
    
    private func _readDataFromMicrophone() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(self.sampleRate), channels: 1, interleaved: false)
        
        guard let formatConverter =  AVAudioConverter(from:inputFormat, to: recordingFormat!)
        else {
            return
        }
        // Install a tap on the audio engine with the buffer size and the input format.
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: inputFormat) { (buffer, time) in
            
            self.conversionQueue.async { [self] in
                // Convert the microphone input to the recording format required
                let outputBufferCapacity = AVAudioFrameCount(buffer.duration * recordingFormat!.sampleRate)
                
                guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat!, frameCapacity: outputBufferCapacity) else {
                    print("Failed to create new pcm buffer")
                    return
                }
                pcmBuffer.frameLength = outputBufferCapacity
                
                var error: NSError? = nil
                let inputBlock: AVAudioConverterInputBlock = {inNumPackets, outStatus in
                    outStatus.pointee = AVAudioConverterInputStatus.haveData
                    return buffer
                }
                formatConverter.convert(to: pcmBuffer, error: &error, withInputFrom: inputBlock)
                
                if error != nil {
                    print(error!.localizedDescription)
                }
                else {
                    self.pushStream.write((pcmBuffer.data()))
                }
            }
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
