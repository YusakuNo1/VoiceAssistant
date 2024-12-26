enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct ResponseData {
    let data: Data
    let headers: [String: String]
}

class ApiManager {
    private var credentials: Credentials?
    private var chatId: String?
    private var appendChatMessages: (String, [Message]) -> Void
    
    init(appendChatMessages: @escaping (String, [Message]) -> Void) {
        self.appendChatMessages = appendChatMessages
    }

    func getCredentials(completion: @escaping (Result<Credentials, Error>) -> Void) {
        if let credentials = self.credentials {
            completion(.success(credentials))
            return
        }
        
        let headers: [String: String] = [
            "Content-Type": "application/json",
        ]
        return self.request(method: HttpMethod.get, endpoint: "/credentials", headers: headers, httpBody: nil) { result in
            switch result {
            case .success(let responseData):
                do {
                    let credentials = try JSONDecoder().decode(Credentials.self, from: responseData.data)
                    self.credentials = credentials
                    completion(.success(credentials))
                } catch {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendChatMessages(message: String, imageList: [Image], completion: @escaping (Result<String, Error>) -> Void) {
        var httpBody: Data!
        do {
            var messageContentList: [MessageContent] = [MessageContent(text: message)]
            for image in imageList {
                messageContentList.append(MessageContent(image: image))
            }

            let lmRequestBody = LanguageModelRequestBody(messages: [
                Message(role: Role.user, content: messageContentList)
            ])
            httpBody = try JSONEncoder().encode(lmRequestBody)
        } catch {
            completion(.failure(error))
            return
        }

        let isNewChat = self.chatId == nil
        var headers: [String: String] = [
            "Content-Type": "application/json",
        ]
        if self.chatId != nil {
            headers["chat-id"] = self.chatId
        }

        self.request(method: .post, endpoint: "/chat", headers: headers, httpBody: httpBody) { result in
            switch result {
            case .success(let responseData):
                guard let chatId = responseData.headers["chat-id"], let responseString = String(data: responseData.data, encoding: .utf8) else {
                    completion(.failure(URLError(.badServerResponse)))
                    return
                }
                self.chatId = chatId
                
                if !isNewChat {
                    self.appendChatMessages(chatId, [
                        Message(role: Role.user, content: [MessageContent(text: message)]),
                        Message(role: Role.assistant, content: [MessageContent(text: responseString)]),
                    ])
                    completion(.success(responseString))
                } else {
                    self.getChatHistory(chatId: chatId) { result in
                        switch result {
                        case .success(let messages):
                            self.appendChatMessages(chatId, messages)
                            completion(.success(responseString))
                        case.failure(let error):
                            completion(.failure(error))
                        }
                    }
                }                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func resetChatId() {
        self.chatId = nil
    }
    
    private func getChatHistory(chatId: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        let headers: [String: String] = [
            "Content-Type": "application/json",
            "chat-id": chatId,
        ]

        self.request(method: .get, endpoint: "/chat_history", headers: headers, httpBody: nil) { result in
            switch result {
            case .success(let responseData):
                let chatHistoryResponseString = String(data: responseData.data, encoding: .utf8)!
                if let response = try? JSONDecoder().decode(ChatHistoryResponse.self, from: Data(chatHistoryResponseString.utf8)) {
                    completion(.success(response.messages))
                } else {
                    completion(.failure(URLError(.badServerResponse)))
                }
            case.failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func request(method: HttpMethod, endpoint: String, headers: [String: String], httpBody: Data?, completion: @escaping (Result<ResponseData, Error>) -> Void) {
        guard let url = URL(string: "\(API_HOST)\(endpoint)") else {
            DispatchQueue.main.async {
                completion(.failure(URLError(.badURL)))
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        for header in headers {
            request.setValue(header.1, forHTTPHeaderField: header.0)
        }

        if let httpBody = httpBody {
            request.httpBody = httpBody
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Get headers from response
            var headers: [String: String] = [:]
            if let httpResponse = response as? HTTPURLResponse {
                for field in httpResponse.allHeaderFields {
                    if let key = field.key as? String, let value = field.value as? String {
                        headers[key] = value
                    }
                }
            }

            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                }
                else if let data = data {
                    let responseData = ResponseData(data: data, headers: headers)
                    completion(.success(responseData))
                } else {
                    completion(.failure(error ?? URLError(.badServerResponse)))
                }
            }
        }
        task.resume()
    }
}
