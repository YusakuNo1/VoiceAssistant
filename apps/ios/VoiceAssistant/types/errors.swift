class HttpError: Error {
    var code: Int
    var message: String
    
    init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}
