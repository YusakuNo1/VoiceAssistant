import UIKit
import AVFoundation

class RemoteSpeechManager: AbstractSpeechManager {
    private var audioPlayer: AVAudioPlayer? = nil
    private var conversionQueue = DispatchQueue(label: "conversionQueue")
    private var audioDataStream: Data = Data()
    private var outputStream = OutputStream()
    private var _speechRecognizing: Bool = false

    override func recognize(imageList: [Image]) {
        if self._speechRecognizing {
            return
        } else {
            self._speechRecognizing = true
        }

        self._setAudioMode(mode: .Record)
        self.updateProgress(.Listen)
        self.audioDataStream.removeAll()

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: self.busId)
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(self.sampleRate), channels: 1, interleaved: false)
        
        guard let formatConverter =  AVAudioConverter(from:inputFormat, to: recordingFormat!)
        else {
            return
        }
        
        var noSoundDurationSum: TimeInterval = 0
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
                        self.audioDataStream.append(data)
                    }
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

    override func synthesize(text: String) {
        self.apiManager.speechSynthesize(text: text) { result in
            switch result {
            case .success(let responseData):
                self._setAudioMode(mode: .Playback)
                self.updateProgress(.Speak)
                do {
                    self.audioPlayer = try AVAudioPlayer(data: responseData)
                    self.audioPlayer?.play()
                    self.updateProgress(.Idle)
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            case.failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    override func stopSpeechRecognize(imageList: [Image]) {
        if !self._speechRecognizing {
            return
        }

        self.updateProgress(.Idle)
        self._speechRecognizing = false

        self.audioEngine.stop()
        self.audioEngine.inputNode.removeTap(onBus: self.busId)

        self.apiManager?.speechRecognize(data: self.audioDataStream) { result in
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
