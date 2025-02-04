import llmfarm_core

let maxOutputLength = 1024
//let systemPrompt = "You are a helpful assistant, answer questions in few short sentences.\nIf it's for a task from the user, response in JSON format with {\"task\": \"task-type-name\", \"parameters\": {\"key\": \"value\"}"
let systemPrompt = "You are a helpful assistant, answer questions in few short sentences."

//let modelName = "qwen2.5-3b-instruct-q5_0" // Working, but not very good answer
//let modelName = "qwen2.5-3b-instruct-q6_k" // Working, quality is not bad
//let modelName = "Qwen2.5-Coder-3B-Instruct-Q8_0"
let modelName = "qwen2.5-coder-1.5b-instruct-q8_0"
//let modelName = "qwen2.5-3b-instruct-q8_0" // Out of memory for iPhone 13 Pro Max
//let modelName = "Phi-3.5-mini-instruct-Q8_0" // Out of memory for iPhone 13 Pro Max
//let modelName = "Phi-3.5-mini-instruct-TQ2_0" // Not working because TQ2 is not implmeneted in llama.cpp
//let modelName = "Phi-3.5-mini-instruct-F16" // Out of memory for iPhone 13 Pro Max

class LocalLlmManager {
    static let shared = LocalLlmManager()

    private var filePath: String!
    private var ai: AI!
    
    private init() {
    }
    
    private func initAI() {
        if self.ai != nil && self.ai.model == nil {
            return
        }

        self.filePath = getFilePath(forResource: modelName, ofType: "gguf")!
        self.ai = AI(_modelPath: self.filePath, _chatName: "chat")
    }

    func sendChatMessages(messages: [Message], completion: @escaping (Result<String, Error>) -> Void) {
        self.initAI()
        
        var total_output = 0

        func mainCallback(_ str: String, _ time: Double) -> Bool {
            print("\(str)",terminator: "")
            total_output += str.count
            if(total_output > maxOutputLength){
                return true
            }
            return false
        }

        //load model
        var params:ModelAndContextParams = .default

        //set custom prompt format
//        params.promptFormat = .Custom
        params.promptFormat = .None
//        params.custom_prompt_format = """
//        SYSTEM: You are a helpful, respectful and honest assistant.
//        USER: {prompt}
//        ASSISTANT:
//        """
//        let input_text = "State the meaning of life"

        params.use_metal = true

        //Uncomment this line to add lora adapter
        //params.lora_adapters.append(("lora-open-llama-3b-v2-q8_0-shakespeare-LATEST.bin",1.0 ))

        //_ = try? ai.loadModel_sync(ModelInference.LLama_gguf,contextParams: params)
        ai.initModel(ModelInference.LLama_gguf, contextParams: params)
        if ai.model == nil{
            print( "Model load eror.")
            exit(2)
        }
        // to use other inference like RWKV set ModelInference.RWKV
        // to use old ggjt_v3 llama models use ModelInference.LLama_bin

        // Set mirostat_v2 sampling method
        ai.model?.sampleParams.mirostat = 2
        ai.model?.sampleParams.mirostat_eta = 0.1
        ai.model?.sampleParams.mirostat_tau = 5.0

        do {
            try ai.loadModel_sync()

            let input = createPrompt(messages: messages)
//            let startTime = Date()
            let output = try ai.model?.predict(input, mainCallback)
//            print(String(format: "* * *", output!))
            // print delta time
//            let deltaTime = Date().timeIntervalSince(startTime)
//            print("\nExecution time: \(deltaTime) seconds\n")
            completion(.success(output!))
        }
        catch {
            print("* * * \(error)")
        }
    }
    
    private func convertDictToJsonString(dict: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                print("Error: Could not convert JSON data to string")
                return nil
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func sampleTools() -> String {
        let get_weather_api: [String: Any] = [
            "type": "function",
            "function": [
                "name": "get_weather",
                "description": "Get the current weather for a location",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "location": [
                            "type": "str",
                            "description": "The city and state, e.g. San Francisco, New York",
                        ],
                        "unit": [
                            "type": "str",
                            "enum": ["celsius", "fahrenheit"],
                            "description": "The unit of temperature to return",
                        ],
                    ],
                    "required": ["location"],
                ],
            ],
        ]
        
        let toolPrompt = """
You are a helpful assistant.

# Tools

You may call one or more functions to assist with the user query.        
You are provided with function signatures within <tools></tools> XML tags.
"""
        
        let formatPrompt = """
For each function call, return a json object with function name and arguments within <tool_call></tool_call> XML tags:
<tool_call>
{"name": <function-name>, "arguments": <args-json-object>}
</tool_call>
"""
        

        if let jsonString = convertDictToJsonString(dict: get_weather_api) {
            return "\(toolPrompt)\n<tools>\n\(jsonString)\n</tools>\n\n\(formatPrompt)"
        } else {
            return ""
        }
        
        
//        let jsonString = convertDictToJsonString(dict: get_weather_api)
//        let comparePrompt = "\(toolPrompt)\n<tools>\n\(jsonString!)\n</tools>\n\n\(formatPrompt)"
//        print("* * * * * * compare prompt\n", comparePrompt)
//        
//        
//        
//        return """
//You are a helpful assistant.
//
//# Tools
//
//You may call one or more functions to assist with the user query.
//
//You are provided with function signatures within <tools></tools> XML tags:
//<tools>
//{"type": "function", "function": {"name": "get_weather", "description": "Get the current weather for a location", "parameters": {"type": "object", "properties": {"location": {"type": "str", "description": "The city and state, e.g. San Francisco, New York"}, "unit": {"type": "str", "enum": ["celsius", "fahrenheit"], "description": "The unit of temperature to return"}}, "required": ["location"]}}}
//</tools>
//
//For each function call, return a json object with function name and arguments within <tool_call></tool_call> XML tags:
//<tool_call>
//{"name": <function-name>, "arguments": <args-json-object>}
//</tool_call>
//"""
    }

    private func createPrompt(messages: [Message]) -> String {
        if messages.isEmpty {
            return ""
        }

        var combinedMessages: [Message] = []
        if messages[0].role != .system {
            let systemPrompt = "\(systemPrompt)\n\(self.sampleTools())"
            let systemMessage: Message = Message(role: .system, content: [MessageContent(text: systemPrompt)])
            combinedMessages.insert(systemMessage, at: 0)
        }

        for message in messages {
            combinedMessages.append(message)
        }
        
        return LlmUtils.createPrompt(combinedMessages, .ChatML)
//        return LlmUtils.createPrompt(combinedMessages, .PlainText)
    }

    private func getFilePath(forResource resource: String, ofType type: String?) -> String? {
        if let path = Bundle.main.path(forResource: resource, ofType: type) {
            return path
        } else {
            print("File not found: \(resource).\(type ?? "")") // Handle the case where the file isn't found
            return nil
        }
    }
}
