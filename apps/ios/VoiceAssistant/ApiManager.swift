enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

class ApiManager {
    private var _credentials: Credentials?
    
    func getCredentials(completion: @escaping (Result<Credentials, Error>) -> Void) {
        if let credentials = self._credentials {
            completion(.success(credentials))
            return
        }
        
        return self._request(method: HttpMethod.get, endpoint: "/credentials", httpBody: nil) { result in
            switch result {
            case .success(let credentialsData):
                do {
                    let credentials = try JSONDecoder().decode(Credentials.self, from: credentialsData)
                    self._credentials = credentials
                    completion(.success(credentials))
                } catch {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendChatMessages(message: String, completion: @escaping (Result<String, Error>) -> Void) {
        var httpBody: Data!
        do {
            let lmRequestBody = LanguageModelRequestBody(messages: [
                Message(role: "system", content: SYSTEM_PROMPT),
                Message(role: "user", content: message)
            ])
            httpBody = try JSONEncoder().encode(lmRequestBody)
        } catch {
            completion(.failure(error))
            return
        }

        self._request(method: HttpMethod.post, endpoint: "/chat", httpBody: httpBody) { result in
            switch result {
            case .success(let data):
                guard let responseString = String(data: data, encoding: .utf8) else {
                    completion(.failure(URLError(.badServerResponse)))
                    return
                }
                completion(.success(responseString))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func _request(method: HttpMethod, endpoint: String, httpBody: Data?, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: "\(API_HOST)\(endpoint)") else {
            DispatchQueue.main.async {
                completion(.failure(URLError(.badURL)))
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let httpBody = httpBody {
            request.httpBody = httpBody
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                }
                else if let data = data {
                    completion(.success(data))
                } else {
                    completion(.failure(error ?? URLError(.badServerResponse)))
                }
            }
        }
        task.resume()
    }
}
