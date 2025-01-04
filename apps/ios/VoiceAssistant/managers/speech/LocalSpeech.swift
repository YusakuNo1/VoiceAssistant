import UIKit
import AVFoundation

class LocalSpeech: AbstractSpeech {
    private var _conversionQueue = DispatchQueue(label: "conversionQueue")
    private var _speechConfig: SPXSpeechConfiguration!
    private var _audioConfig: SPXAudioConfiguration!
    private var _reco: SPXSpeechRecognizer!
    private var _pushStream: SPXPushAudioInputStream!

    override func recognize(imageList: [Image]) {
        self._setAudioMode(mode: .Record)
        
        self._apiManager.getCredentials() { result in
            switch result {
            case .success(let credentials):
                try! self._speechConfig = SPXSpeechConfiguration(subscription: credentials.speech.key, region: credentials.speech.region)
                self._speechConfig?.speechRecognitionLanguage = "en-US"
                
                self._pushStream = SPXPushAudioInputStream()
                self._audioConfig = SPXAudioConfiguration(streamInput: self._pushStream)
                self._reco = try! SPXSpeechRecognizer(speechConfiguration: self._speechConfig!, audioConfiguration: self._audioConfig!)
                self._reco.addRecognizedEventHandler() { reco, evt in
                    if let message = evt.result.text {
                        self._onSpeechRecognized(message: message, imageList: imageList)
                    }
                }
                self._reco.addCanceledEventHandler { reco, evt in
                    print("Recognition canceled: \(evt.errorDetails?.description ?? "(no result)")")
                    self._updateProgress(.Idle)
                }
                try! self._reco.recognizeOnceAsync({ srresult in
                    self._audioEngine.stop()
                    self._audioEngine.inputNode.removeTap(onBus: self._busId)
                    self._pushStream.close()
                })
                self._readDataFromMicrophone()
                self._updateProgress(.Listen)
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    override func synthesize(text: String) {
        self._setAudioMode(mode: .Playback)
        self._updateProgress(.Speak)
        
        self._apiManager.getCredentials() { result in
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
                self._updateProgress(.Idle)
            case .failure(let error):
                print("error \(error) happened")
                self._updateProgress(.Idle)
            }
        }
    }
    
    private func _readDataFromMicrophone() {
        let inputNode = self._audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: self._busId)
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(self._sampleRate), channels: 1, interleaved: false)
        
        guard let formatConverter =  AVAudioConverter(from:inputFormat, to: recordingFormat!)
        else {
            return
        }
        // Install a tap on the audio engine with the buffer size and the input format.
        self._audioEngine.inputNode.installTap(onBus: self._busId, bufferSize: AVAudioFrameCount(self._bufferSize), format: inputFormat) { (buffer, time) in
            
            self._conversionQueue.async { [self] in
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
                    self._pushStream.write((pcmBuffer.data()))
                }
            }
        }
        self._audioEngine.prepare()
        do {
            try self._audioEngine.start()
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
