from jinja2 import Template
from dataclasses import asdict

from src.config.env import aoai_chat_endpoint
from src.utils.loggers import log
from .types import Message, Request
from src.utils.str_utils import escape_json_string


system_prompt = """You are a helpful assistant.
{{ context }}
"""

# The key is chat_id, the value is a list of messages
hisotry_dict: dict[str, list[Message]] = {}
# hisotry_dict["test-chat-id"] = [Message(role="system", content="first line\n\"second line\"")]


def _get_history_messages(chat_id: str) -> list[Message]:
    messages = hisotry_dict.get(chat_id, [])
    if len(messages) > 0:
        return messages

    # Build the initial message, including RAG (if required)
    template = Template(system_prompt)
    return [Message(role="system", content=template.render(context="").strip())]


async def chat(chat_id: str, request: Request):
    from azure.ai.inference import ChatCompletionsClient
    from azure.identity import DefaultAzureCredential

    client = ChatCompletionsClient(
        endpoint=aoai_chat_endpoint,
        credential=DefaultAzureCredential(exclude_interactive_browser_credential=False),
        credential_scopes=["https://cognitiveservices.azure.com/.default"],
        api_version="2024-06-01",  # Azure OpenAI api-version. See https://aka.ms/azsdk/azure-ai-inference/azure-openai-api-versions
    )

    history_messages = _get_history_messages(chat_id)
    request_messages = request.messages
    messages: list[dict] = []
    for message in (history_messages + request_messages):
        messages.append(asdict(message))

    response = client.complete(
        stream=True,
        messages=messages,
    )

    response_str = ""
    for update in response:
        chunk = update.choices[0].delta.content
        if chunk: # Avoid None to be sent to the response
            response_str += chunk
            yield chunk
        # await asyncio.sleep(1) # Simulate a delay

    history_messages.extend(request_messages)
    history_messages.extend([Message(role="assistant", content=response_str)])
    hisotry_dict[chat_id] = history_messages
    

def chat_history(chat_id: str):
    messages = []
    for message in hisotry_dict.get(chat_id, []):
        if message.role == "system":
            continue # Skip system messages

        message_dict = asdict(message)
        if isinstance(message_dict["content"], list):
            for content in message_dict["content"]:
                if content["type"] == "text":
                    content["text"] = escape_json_string(content["text"])
                # elif content["type"] == "image_url":
                #     content["image_url"]["url"] = escape_json_string(content["image_url"]["url"])
        else:
            message_dict["content"] = escape_json_string(message_dict["content"])
        messages.append(message_dict)
    return { "messages": messages }
