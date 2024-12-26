import AVFoundation

extension AVAudioPCMBuffer {
    func data() -> Data {
        var nBytes = 0
        nBytes = Int(self.frameLength * (self.format.streamDescription.pointee.mBytesPerFrame))
        var range: NSRange = NSRange()
        range.location = 0
        range.length = nBytes
        let buffer = NSMutableData()
        buffer.replaceBytes(in: range, withBytes: (self.int16ChannelData![0]))
        return buffer as Data
    }
    
    var duration: TimeInterval {
        format.sampleRate > 0 ? .init(frameLength) / format.sampleRate : 0
    }
}
