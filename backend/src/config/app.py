from dataclasses import dataclass
from enum import Enum
from fastapi import FastAPI
from .types import AppConfig


app = FastAPI()
app_config = AppConfig(
    language="en-us",
    recognition_timeout="3000", # 3 seconds
)
