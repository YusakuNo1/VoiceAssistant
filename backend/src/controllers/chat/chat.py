import uuid
from typing import Annotated
from fastapi import Header
from fastapi.responses import StreamingResponse
from dataclasses import asdict

from src.config.app import app
from src.config.env import aoai_chat_endpoint
from .types import Request


async def chat(request: Request):
    from azure.ai.inference import ChatCompletionsClient
    from azure.identity import DefaultAzureCredential

    client = ChatCompletionsClient(
        endpoint=aoai_chat_endpoint,
        credential=DefaultAzureCredential(exclude_interactive_browser_credential=False),
        credential_scopes=["https://cognitiveservices.azure.com/.default"],
        api_version="2024-06-01",  # Azure OpenAI api-version. See https://aka.ms/azsdk/azure-ai-inference/azure-openai-api-versions
    )

    messages = asdict(request)["messages"]
    response = client.complete(
        stream=True,
        messages=messages,
    )

    for update in response:
        chunk = update.choices[0].delta.content
        if chunk: # Avoid None to be sent to the response
            yield chunk
        # await asyncio.sleep(1) # Simulate a delay


# Sample query:
#   curl -X POST http://127.0.0.1:8000/chat --header "Content-Type: application/json" --header "chat-id: my-id-123" --data '{ "messages": [{ "role": "system", "content": "you are a helpful assistant" }, { "role": "user", "content": "where is the headquarter of microsoft" }] }'
@app.post("/chat")
async def chat_controller(request: Request, chat_id: Annotated[str | None, Header()] = None):
    if chat_id is None:
        chat_id = uuid.uuid4().hex
    
    headers = {
        "Content-Type": "text/html", # "text/plain" can't support streaming in browser, while "text/html" can
        "chat-id": chat_id,
    }
    return StreamingResponse(chat(request), headers=headers)
