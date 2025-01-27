import UIKit
import llmfarm_core

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        run()
        
//        let message = Message(role: .user, content: [MessageContent(text: "please create latex formula for power of 3")])
//        LlmManager.shared.sendChatMessages(messages: [message]) { (result) in
//            print("* * * \(result)")
//        }
        return true
    }
    
    private func getFilePath(forResource resource: String, ofType type: String?) -> String? {
        if let path = Bundle.main.path(forResource: resource, ofType: type) {
            return path
        } else {
            print("File not found: \(resource).\(type ?? "")") // Handle the case where the file isn't found
            return nil
        }
    }

    private func run() {
        let maxOutputLength = 256
        var total_output = 0

        func mainCallback(_ str: String, _ time: Double) -> Bool {
            print("\(str)",terminator: "")
            total_output += str.count
            if(total_output>maxOutputLength){
                return true
            }
            return false
        }


        //load model
//        let filePath = "/Users/weiwu/Workspaces/OpenSource/1_shared_models/guff/open_llama_3b_v2_Q8_0.gguf"
        let filePath = getFilePath(forResource: "qwen2.5-3b-instruct-q2_k", ofType: "gguf")!
        let ai = AI(_modelPath: filePath,_chatName: "chat")
        var params:ModelAndContextParams = .default

        //set custom prompt format
        params.promptFormat = .Custom
        params.custom_prompt_format = """
        SYSTEM: You are a helpful, respectful and honest assistant.
        USER: {prompt}
        ASSISTANT:
        """
        let input_text = "State the meaning of life"

        params.use_metal = true

        //Uncomment this line to add lora adapter
        //params.lora_adapters.append(("lora-open-llama-3b-v2-q8_0-shakespeare-LATEST.bin",1.0 ))

        //_ = try? ai.loadModel_sync(ModelInference.LLama_gguf,contextParams: params)
        ai.initModel(ModelInference.LLama_gguf,contextParams: params)
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
//            //eval with callback
//            let output = try ai.model?.predict(input_text, mainCallback)
//            print(String(format: "* * *", output!))

            let questions = [
                "create a math formula for \"power of x\" in latex format",
//                "tell me another joke about cat",
            ]
            for question in questions {
                let startTime = Date()
                let output = try ai.model?.predict(question, mainCallback)
                print(String(format: "* * *", output!))
                // print delta time
                let deltaTime = Date().timeIntervalSince(startTime)
                print("\nExecution time: \(deltaTime) seconds\n")
            }
        }
        catch {
            print("* * * \(error)")
        }

    }
}
