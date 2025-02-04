<|im_start|>system
You are a helpful AI assistant.<|im_end|>

<|im_start|>user
Describe this image.<|im_end|>

<|im_start|>user
{"image_url": "https://example.com/image.jpg"}<|im_end|>

<|im_start|>assistant
This appears to be an image. Let me analyze it...<|im_end|>



curl -X POST http://127.0.0.1/chat-llamacpp --header "Content-Type: application/json" --header "chat-id: my-id-123" --data '{ "messages": [{ "role": "user", "content": "what are the tools I can try with?" }] }'


curl -X POST http://127.0.0.1/chat-llamacpp-plain --header "Content-Type: application/json" --header "chat-id: my-id-123" --data '{ "input": "<|im_start|>system\nYou are a helpful AI assistant.<|im_end|>\n\n<|im_start|>user\nDescribe this image.<|im_end|>\n\n<|im_start|>user\n{"image_url": "https://example.com/image.jpg"}<|im_end|>\n\n<|im_start|>assistant\nThis appears to be an image. Let me analyze it...<|im_end|>" }'


curl -X POST http://127.0.0.1/chat-llamacpp --header "Content-Type: application/json" --header "chat-id: my-id-123" --data '{ "messages": [{ "role": "user", "content": [{ "type": "text", "text": "what is in the image?" }, { "type": "image_url", "image_url": { "url": "data:image/png;base64,01234ABCDE" } }] }] }'

curl -X POST http://127.0.0.1/chat-llamacpp --header "Content-Type: application/json" --header "chat-id: my-id-123" --data '{ "messages": [{ "role": "user", "content": [{ "type": "text", "text": "what is in the image?" }, { "type": "image_url", "image_url": { "url": "data:image/png;base64,01234ABCDE" } }] }] }'
