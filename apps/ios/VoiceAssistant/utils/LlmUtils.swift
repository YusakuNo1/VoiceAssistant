class LlmUtils {
    enum PromptType {
        case PlainText
        case ChatML        // <|im_start|> <|im_end|>
    }
    
    static func createPrompt(_ messages: [Message], _ type: PromptType) -> String {
        switch type {
        case .PlainText:
            return createPromptPlainText(messages)
        case .ChatML:
            return createPromptChatML(messages)
        }
    }
    
    static func getLlamacppFuncParams(response: String) -> ([String: Any])? {
        var toolCallStr: String? = nil
        if response.hasPrefix("<tool_call>") {
            toolCallStr = String(response.split(separator: "<tool_call>")[1].split(separator: "</tool_call>")[0])
        } else if response.hasPrefix("```json") {
            toolCallStr = String(response.split(separator: "```json")[1].split(separator: "```")[0])
        }

        if let data = toolCallStr?.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]  {
            return json
        } else {
            return nil
        }
    }
    
    private static func createPromptChatML(_ messages: [Message]) -> String {
        var rows: [String] = []
        for message in messages {
            switch message.role {
            case .system:
                rows.append("<|im_start|>system")
            case .user:
                rows.append("<|im_start|>user")
            case .assistant:
                rows.append("<|im_start|>assistant")
            }
            
            rows.append(combineMessageContent(message.content))
            rows.append("<|im_end|>")
        }
        
        var prompt = rows.joined(separator: "\n")
        prompt += "<|im_start|>assistant\n"           // maybe we need this at the end
        return prompt
    }
    
    private static func createPromptPlainText(_ messages: [Message]) -> String {
//        var prompt = ""
//        for message in messages {
//            switch message.role {
//            case .system:
//                prompt += ""
//            case .user:
//                prompt += "User:\n"
//            case .assistant:
//                prompt += "Assistant:\n"
//            }
//            
//            prompt += combineMessageContent(message.content)
//            prompt += "\n"
//        }        
//        return prompt
        
        fatalError(#function + " not working properly yet.")
    }
    
    private static func combineMessageContent(_ content: [MessageContent]) -> String {
        var combinedContent: String = ""
        for item in content {
            // TODO: handle multi-modal data later
            if let text = item.text {
                combinedContent += "\(text)"
            }
        }
        return combinedContent
    }
}
