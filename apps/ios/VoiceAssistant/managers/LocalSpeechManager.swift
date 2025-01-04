import UIKit
import AVFoundation

class LocalSpeechManager: AbstractSpeechManager {
    private var credentials: Credentials?
    private var conversionQueue = DispatchQueue(label: "conversionQueue")
    private var speechConfig: SPXSpeechConfiguration!
    private var audioConfig: SPXAudioConfiguration!
    private var reco: SPXSpeechRecognizer!
    private var pushStream: SPXPushAudioInputStream!
    
    override func recognize(imageList: [Image]) {
        self._setAudioMode(mode: .Record)
        
        self.apiManager.getCredentials() { result in
            switch result {
            case .success(let credentials):
                try! self.speechConfig = SPXSpeechConfiguration(subscription: credentials.speech.key, region: credentials.speech.region)
                self.speechConfig?.speechRecognitionLanguage = "en-US"
                
                self.pushStream = SPXPushAudioInputStream()
                self.audioConfig = SPXAudioConfiguration(streamInput: self.pushStream)
                self.reco = try! SPXSpeechRecognizer(speechConfiguration: self.speechConfig!, audioConfiguration: self.audioConfig!)
                self.reco.addRecognizedEventHandler() { reco, evt in
                    if let message = evt.result.text {
                        self._onSpeechRecognized(message: message, imageList: imageList)
                    }
                }
                self.reco.addCanceledEventHandler { reco, evt in
                    print("Recognition canceled: \(evt.errorDetails?.description ?? "(no result)")")
                    self.updateProgress(.Idle)
                }
                try! self.reco.recognizeOnceAsync({ srresult in
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: self.busId)
                    self.pushStream.close()
                })
                self._readDataFromMicrophone()
                self.updateProgress(.Listen)
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    override func synthesize(text: String) {
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
                
                let result = try! synthesizer.speakText(text)
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
    
    private func _readDataFromMicrophone() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: self.busId)
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(self.sampleRate), channels: 1, interleaved: false)
        
        guard let formatConverter =  AVAudioConverter(from:inputFormat, to: recordingFormat!)
        else {
            return
        }
        // Install a tap on the audio engine with the buffer size and the input format.
        audioEngine.inputNode.installTap(onBus: self.busId, bufferSize: AVAudioFrameCount(bufferSize), format: inputFormat) { (buffer, time) in
            
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
