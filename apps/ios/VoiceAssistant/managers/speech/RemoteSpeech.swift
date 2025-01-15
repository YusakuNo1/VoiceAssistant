import UIKit
import AVFoundation

class RemoteSpeech: AbstractSpeech, AVAudioPlayerDelegate {
    private var _audioPlayer: AVAudioPlayer? = nil
    private var _conversionQueue = DispatchQueue(label: "conversionQueue")
    private var _audioDataStream: Data = Data()
    private var _speechRecognizing: Bool = false

    override func recognize(imageList: [Image]) {
        if self._speechRecognizing {
            return
        } else {
            self._speechRecognizing = true
        }

        self._setAudioMode(mode: .Record)
        self._updateProgress?(.Listen)
        self._audioDataStream.removeAll()

        let inputNode = self._audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: self._busId)
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(self._sampleRate), channels: 1, interleaved: false)
        
        guard let formatConverter =  AVAudioConverter(from:inputFormat, to: recordingFormat!)
        else {
            return
        }
        
        var noSoundDurationSum: TimeInterval = 0
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
                } else {
                    let audioData = AudioUtils.getAudioData(pcmBuffer)
                    if audioData.noSoundDuration > 0 {
                        noSoundDurationSum += audioData.noSoundDuration
                    } else {
                        noSoundDurationSum = 0
                    }

                    Logger.log(message: "no sound duration: \(noSoundDurationSum)")
                    if noSoundDurationSum > SPEECH_RECOGNITION_TIMEOUT {
                        self.stopSpeechRecognize(imageList: imageList)
                    }

                    if let data = audioData.data {
                        self._audioDataStream.append(data)
                    }
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

    override func synthesize(text: String) {
        ApiManager.shared.speechSynthesize(text: text) { result in
            switch result {
            case .success(let responseData):
                self._setAudioMode(mode: .Playback)
                self._updateProgress?(.Speak)
                do {
                    self._audioPlayer = try AVAudioPlayer(data: responseData)
                    self._audioPlayer?.delegate = self
                    self._audioPlayer?.volume = self._audioPlayerVolume
                    self._audioPlayer?.play()
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            case.failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self._updateProgress?(.Idle)
    }

    // MARK: - Private
    
    private func stopSpeechRecognize(imageList: [Image]) {
        if !self._speechRecognizing {
            return
        }

        self._speechRecognizing = false

        self._audioEngine.stop()
        self._audioEngine.inputNode.removeTap(onBus: self._busId)

        ApiManager.shared.speechRecognize(data: self._audioDataStream) { result in
            print("Recognition result: \(result)")
            switch result {
            case .success(let message):
                self._onSpeechRecognized(message: message, imageList: imageList)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
