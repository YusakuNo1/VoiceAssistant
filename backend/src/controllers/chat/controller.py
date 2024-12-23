import uuid
from typing import Annotated
from fastapi import Header
from fastapi.responses import StreamingResponse

from src.config.app import app
from src.utils.loggers import log
from .types import Request
from .service import chat


# Sample query:
#   curl -X POST http://127.0.0.1:8000/chat --header "Content-Type: application/json" --header "chat-id: my-id-123" --data '{ "messages": [{ "role": "system", "content": "you are a helpful assistant" }, { "role": "user", "content": "where is the headquarter of microsoft" }] }'
@app.post("/chat")
async def chat_controller(request: Request, chat_id: Annotated[str | None, Header()] = None):
    if chat_id is None:
        chat_id = uuid.uuid4().hex
        log(f"* Create chat_id: {chat_id}")
    else:
        log(f"* Request chat_id: {chat_id}")
    
    headers = {
        "Content-Type": "text/html", # "text/plain" can't support streaming in browser, while "text/html" can
        "chat-id": chat_id,
    }
    return StreamingResponse(chat(chat_id, request), headers=headers)
