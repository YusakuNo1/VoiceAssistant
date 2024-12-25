from dataclasses import dataclass


@dataclass
class MessageContentStr:
    type: str
    text: str

@dataclass
class MessageContentImageUrlContent:
    url: str

@dataclass
class MessageContentImageUrl:
    type: str
    image_url: MessageContentImageUrlContent

@dataclass
class Message:
    role: str
    content: str | list[MessageContentStr | MessageContentImageUrl]

@dataclass
class Request:
    messages: list[Message]
