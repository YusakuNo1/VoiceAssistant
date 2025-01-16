from enum import Enum

class LoggerLevel(Enum):
    INFO = 1
    WARNING = 2
    ERROR = 3

current_logger_level = LoggerLevel.INFO

def log(message: str, level: LoggerLevel = LoggerLevel.INFO):
    if level.value >= current_logger_level.value:
        print(f"[{level.name}] {message}")
