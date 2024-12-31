////let API_HOST = "http://127.0.0.1:8000"
//let API_HOST = "http://192.168.254.104:8000"
////let API_HOST = "http://10.16.176.13:8000"

let API_HOST = "http://192.168.254.104"
//let API_HOST = "http://10.16.176.13"

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
