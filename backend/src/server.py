import asyncio
import os
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel


load_dotenv()
aoai_chat_endpoint = os.environ["AZURE_OPENAI_CHAT_ENDPOINT"]
ai_speech_service_key = os.environ["AZURE_AI_SPEECH_SERVICE_KEY"]
ai_speech_service_region = os.environ["AZURE_AI_SPEECH_SERVICE_REGION"]

app = FastAPI()


class Message(BaseModel):
    role: str
    content: str

class Request(BaseModel):
    messages: list[Message]


async def chat(request: Request):
    from azure.ai.inference import ChatCompletionsClient
    from azure.identity import DefaultAzureCredential

    client = ChatCompletionsClient(
        endpoint=aoai_chat_endpoint,
        credential=DefaultAzureCredential(exclude_interactive_browser_credential=False),
        credential_scopes=["https://cognitiveservices.azure.com/.default"],
        api_version="2024-06-01",  # Azure OpenAI api-version. See https://aka.ms/azsdk/azure-ai-inference/azure-openai-api-versions
    )

    messages = request.model_dump()["messages"]
    response = client.complete(
        stream=True,
        messages=messages,
    )

    for update in response:
        chunk = update.choices[0].delta.content
        if chunk: # Avoid None to be sent to the response
            yield chunk
        # await asyncio.sleep(1) # Simulate a delay


@app.get("/credentials")
async def credentials():
    return {
        "speech": {
            "key": ai_speech_service_key,
            "region": ai_speech_service_region,
        },
    }

# Sample query:
#   curl -X POST http://127.0.0.1:8000/chat --header "Content-Type: application/json" --data '{ "messages": [{ "role": "system", "content": "you are a helpful assistant" }, { "role": "user", "content": "where is the headquarter of microsoft" }] }'
@app.post("/chat")
async def chat_controller(request: Request):
    return StreamingResponse(chat(request), media_type="text/html") # "text/plain" can't support streaming in browser, while "text/html" can


@app.get("/test")
async def testing():
    async def run():
        for i in range(3):
            yield f"Hello, {i}<br>"
            await asyncio.sleep(1)
    return StreamingResponse(run(), media_type="text/html") # "text/plain" can't support streaming in browser, while "text/html" can
