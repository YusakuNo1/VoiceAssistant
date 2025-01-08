let API_HOST = "http://192.168.254.109"

enum AudioMode {
    case Record
    case Playback
}

enum ProgressState {
    case Idle
    case Init
    case Listen
    case WaitForRes
    case Speak
}

let IMAGE_SIZE: CGFloat = 64
let IMAGE_JPEG_QUALITY: CGFloat = 0.8
let MAX_CELL_THUMBNAILS = 5 // Defined in storyboard

let SPEECH_RECOGNITION_TIMEOUT: TimeInterval = 2 // After this timeout, stop speech recognition
let SPEECH_RECOGNITION_SILENT_THRESHOLD: Float = 150.0

