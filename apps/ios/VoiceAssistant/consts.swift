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
let SPEECH_RECOGNITION_SILENT_THRESHOLD: Float = 1500.0

let ACTION_SUCCESS_MESSAGE = "OK"
let ACTION_SUCCESS_MESSAGE_OPEN_MAP_TEMPLATE = "Let's check %@ on the map!"
let ACTION_SUCCESS_MESSAGE_GET_WEATHER_FAHRENHEIT_TEMPLATE = "In %@, it's %.1f degrees Fahrenheit"

let ACTION_FAILURE_MESSAGE_CHANGE_VOLUME = "Sorry, I can't change the volume"
let ACTION_FAILURE_MESSAGE_GET_WEATHER = "Sorry, I can't get the weather"
let ACTION_FAILURE_MESSAGE_OPEN_BROWSER = "Sorry, I can't open a browser"
