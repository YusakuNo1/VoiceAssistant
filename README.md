# Voice Assistant

## Python Backend Project setup
* Install `requirements.txt` from folder `backend`: `pip install -r requirements.txt`
* Open the root folder from VSCode
* Choose `Run and Debug` -> `Start Debugging`

## Prepare language model
* Download llama.cpp: https://github.com/ggerganov/llama.cpp
* Download the target LLM model (e.g. `git clone https://huggingface.co/katanemo/Arch-Function-3B`) into llama.cpp, name it `models-custom`
* Run script to convert it to GGUF: `python convert_hf_to_gguf.py models-custom --outtype q8_0`, a new file `*.gguf` will be created within folder `models-custom`

## iOS Project setup
* Install CocoaPods: https://cocoapods.org/
* Open terminal with folder `apps/ios`
* Install pods with command: `pod install`
* Open the Xcode workspace `VoiceAssistant.xcworkspace`
* Update `Team` for `Signing & Capabilities`
* Drag the `*.gguf` file into `Build Phases` -> `Copy Bundle Resources`
* In file `LocalLlmManager.swift`, update `modelName` to the file name the gguf model (without extension name) 
* In file `consts.swift`, update `API_HOST` to the IP address the server 
* Run the project
