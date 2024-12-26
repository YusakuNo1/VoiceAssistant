class Logger {
    enum Level: Int {
        case info
        case warning
        case error
    }
    
    static var currentLoggerLevel: Level = .warning
    
    static func log(_ level: Level, _ message: String) {
        if level.rawValue >= currentLoggerLevel.rawValue {
            print("[\(level)] \(message)")
        }
    }
    
    static func log(message: String) {
        let level: Level = .info // Default value
        if level.rawValue >= currentLoggerLevel.rawValue {
            print("[\(level)] \(message)")
        }
    }
}
