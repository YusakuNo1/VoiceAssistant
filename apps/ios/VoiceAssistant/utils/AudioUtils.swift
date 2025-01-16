import AVKit

class AudioData {
    let data: Data?
    let noSoundDuration: TimeInterval
    
    init(data: Data?, noSoundDuration: TimeInterval) {
        self.data = data
        self.noSoundDuration = noSoundDuration
    }
}

class AudioUtils {
    static func getAudioData(_ buffer: AVAudioPCMBuffer) -> AudioData {
        if let channelData = buffer.floatChannelData?[0] {
            var sumOfSquares: Float = 0.0
            for i in 0..<Int(buffer.frameLength) {
                sumOfSquares += channelData[i] * channelData[i]
            }
            let rms = sqrt(sumOfSquares / Float(buffer.frameLength))
            let data = Data(bytes: channelData, count: Int(buffer.frameLength * buffer.format.streamDescription.pointee.mBytesPerFrame))
            let noSoundDuration = rms > SPEECH_RECOGNITION_SILENT_THRESHOLD ? 0 : buffer.duration
            Logger.log(.info, "* rms (float): \(rms)")
            return AudioData(data: data, noSoundDuration: noSoundDuration)
        } else if let channelData = buffer.int16ChannelData?[0] {
            var sumOfSquares: Float = 0.0
            for i in 0..<Int(buffer.frameLength) {
                sumOfSquares += Float(channelData[i]) * Float(channelData[i])
            }
            let rms = sqrt(sumOfSquares / Float(buffer.frameLength))
            let data = Data(bytes: channelData, count: Int(buffer.frameLength * buffer.format.streamDescription.pointee.mBytesPerFrame))
            let noSoundDuration = rms > SPEECH_RECOGNITION_SILENT_THRESHOLD ? 0 : buffer.duration
            Logger.log(.info, "* rms (int16): \(rms)")
            return AudioData(data: data, noSoundDuration: noSoundDuration)
        } else if let channelData = buffer.int32ChannelData?[0] {
            var sumOfSquares: Float = 0.0
            for i in 0..<Int(buffer.frameLength) {
                sumOfSquares += Float(channelData[i]) * Float(channelData[i])
            }
            let rms = sqrt(sumOfSquares / Float(buffer.frameLength))
            let data = Data(bytes: channelData, count: Int(buffer.frameLength * buffer.format.streamDescription.pointee.mBytesPerFrame))
            let noSoundDuration = rms > SPEECH_RECOGNITION_SILENT_THRESHOLD ? 0 : buffer.duration
            Logger.log(.info, "* rms (int32): \(rms)")
            return AudioData(data: data, noSoundDuration: noSoundDuration)
        } else {
            return AudioData(data: nil, noSoundDuration: buffer.duration)
        }
    }
}
