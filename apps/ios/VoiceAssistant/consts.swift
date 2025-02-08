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

let IMAGE_SIZE: CGFloat = 256
let IMAGE_JPEG_QUALITY: CGFloat = 0.7
let MAX_CELL_THUMBNAILS = 5 // Defined in storyboard

let SPEECH_RECOGNITION_TIMEOUT: TimeInterval = 1.2 // After this timeout, stop speech recognition
let SPEECH_RECOGNITION_SILENT_THRESHOLD: Float = 200.0

let LLM_CONTEXT_LENGTH: Int32 = 2048

let ACTION_SUCCESS_MESSAGE = "OK"
let ACTION_SUCCESS_MESSAGE_OPEN_MAP_TEMPLATE = "Let's check %@ on the map!"
let ACTION_SUCCESS_MESSAGE_CHANGE_VOLUME_TEMPLATE = "The volume is changed to %d!"
let ACTION_SUCCESS_MESSAGE_GET_WEATHER_FAHRENHEIT_TEMPLATE = "In %@, it's %.1f degrees Fahrenheit"
let ACTION_SUCCESS_MESSAGE_OPEN_BROWSER_TEMPLATE = "Open browser for URL: %@"
let ACTION_SUCCESS_MESSAGE_FIND_IMAGE_TEMPLATE = "Image for %@ is found!"

let ACTION_FAILURE_MESSAGE_CHANGE_VOLUME = "Sorry, I can't change the volume"
let ACTION_FAILURE_MESSAGE_GET_WEATHER = "Sorry, I can't get the weather"
let ACTION_FAILURE_MESSAGE_OPEN_BROWSER = "Sorry, I can't open a browser"
let ACTION_FAILURE_MESSAGE_FIND_IMAGE = "Sorry, I can't show the image"
