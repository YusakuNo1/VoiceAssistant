//let API_HOST = "http://127.0.0.1:8000"
let API_HOST = "http://192.168.254.104:8000"
//let API_HOST = "http://10.16.176.13:8000"

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

let SYSTEM_PROMPT = "you are a helpful assistant"
