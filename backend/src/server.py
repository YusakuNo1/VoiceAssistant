from typing import Annotated
from fastapi import FastAPI, Header

import src.controllers.chat.controller
import src.controllers.speech.controller
from src.config.app import app


# Sample query:
#  curl http://127.0.0.1:8000/test --header "Content-Type: application/json" --header "x-token: my-x-token"
@app.get("/test")
async def test():
    return {
        "testing": True,
    }
