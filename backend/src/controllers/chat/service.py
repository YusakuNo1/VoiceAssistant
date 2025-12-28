import json
from jinja2 import Template
from dataclasses import asdict
from azure.ai.agents.models import FunctionTool

from src.config.env import (
    aoai_chat_endpoint,
    aoai_key,
    aoai_vision_endpoint,
    chat_model_llamacpp,
    vision_model_llamacpp,
)
from src.utils.loggers import log
from src.utils.str_utils import escape_json_string
from src.utils.prompty_utils import get_endpoint, get_messages
from .types import Message, Request
from . import tools


chat_endpoint = get_endpoint("./chat.prompty")
vision_endpoint = get_endpoint("./vision.prompty")

tools_map = {
    "change_volume": tools.change_volume,
    "find_image": tools.find_image,
    "get_weather": tools.get_weather,
    "open_browser": tools.open_browser,
    "open_map": tools.open_map,
}
functions = FunctionTool(functions=tools_map.values())

def get_llamacpp_func_extra_params(response_str: str) -> dict:
    if response_str.startswith("<tool_call>"):
        tool_call_str = response_str[len("<tool_call>"):-len("</tool_call>")]
        return json.loads(tool_call_str)
    elif response_str.startswith("```json"):
        tool_call_str = response_str[len("```json"):-len("```")]
        return json.loads(tool_call_str)
    else:
        return None

# The key is chat_id, the value is a list of messages
hisotry_dict: dict[str, list[Message]] = {}
# hisotry_dict["test-chat-id"] = [Message(role="system", content="first line\n\"second line\"")]


def _get_history_messages(chat_id: str) -> list[Message]:
    messages = hisotry_dict.get(chat_id, [])
    if len(messages) > 0:
        return messages

    # Build the initial message, including RAG (if required)
    return get_messages("./chat.prompty")

def _use_vision_model(request: Request) -> bool:
    for message in request.messages:
        if message.role != "user":
            continue
        for item in message.content:
            if isinstance(item, dict) and "type" in item and "image_url" in item and item["type"] == "image_url":
                return True
    return False

async def chat(chat_id: str, request: Request):
    from azure.ai.inference import ChatCompletionsClient
    from azure.core.credentials import AzureKeyCredential

    # As of now (2024.12.26), the token price for vision is very different and opposite to the chat token price:
    #  * GPT-4o-mini costs $0.001275 for 150px x 150px image
    #  * GPT-4o costs $0.000638 for 150px x 150px image
    use_vision = _use_vision_model(request)
    log(f"Using vision model: {use_vision}")

    client = ChatCompletionsClient(
        endpoint=(aoai_vision_endpoint if use_vision else aoai_chat_endpoint),
        credential=AzureKeyCredential(aoai_key),
        credential_scopes=["https://cognitiveservices.azure.com/.default"],
        api_version="2025-04-01-preview",  # Azure OpenAI api-version. See https://aka.ms/azsdk/azure-ai-inference/azure-openai-api-versions
    )

    history_messages = _get_history_messages(chat_id)
    request_messages = request.messages
    messages: list[dict] = []
    for message in (history_messages + request_messages):
        messages.append(asdict(message))

    # ISSUE: sometimes streaming stuck when uploading image
    is_streaming = False
    response = client.complete(
        # stream=True,
        stream=is_streaming,
        messages=messages,
        tools=functions.definitions,
    )

    response_str = ""

    if is_streaming:
        for update in response:
            chunk = update.choices[0].delta.content
            if chunk: # Avoid None to be sent to the response
                response_str += chunk
                yield chunk
            # await asyncio.sleep(1) # Simulate a delay
    elif response.choices[0].finish_reason == "tool_calls":
        tool_calls = response.choices[0].message.tool_calls
        for tool_call in tool_calls:
            response_str = await functions.execute(tool_call)
            yield response_str + "\n"
    else:
        response_str = response.choices[0].message.content
        # if response_str is not str, convert it to str
        if not isinstance(response_str, str):
            response_str = str(response_str)
        yield response_str

    history_messages.extend(request_messages)
    history_messages.extend([Message(role="assistant", content=response_str)])
    hisotry_dict[chat_id] = history_messages


async def chat_llamacpp(chat_id: str, request: Request):
    from llama_cpp import Llama

    use_vision = _use_vision_model(request)
    log(f"Using vision model: {use_vision}")

    client = Llama(
      model_path=(vision_model_llamacpp if use_vision else chat_model_llamacpp),
      n_ctx=4096,
    )

    history_messages = _get_history_messages(chat_id)
    request_messages = request.messages
    messages: list[dict] = []
    for message in (history_messages + request_messages):
        messages.append(asdict(message))

    is_streaming = False
    tools = []
    for function in FunctionTool(functions=tools_map.values()).definitions:
        tools.append(function.as_dict())

    response = client.create_chat_completion(
        messages=messages,
        max_tokens=256,
        # stream=True,
        tools=tools,
    )

    response_str = ""

    if is_streaming:
        pass
    #     for update in response:
    #         chunk = update.choices[0].delta.content
    #         if chunk: # Avoid None to be sent to the response
    #             response_str += chunk
    #             yield chunk
    #         # await asyncio.sleep(1) # Simulate a delay
    elif response["choices"][0]["finish_reason"] == "tool_calls":
        # Maybe this path is not used
        tool_calls = response["choices"][0]["message"]["tool_calls"]
        # for tool_call in tool_calls:
        #     tool_call = RequiredFunctionToolCall(tool_call)
        #     response_str = await functions.execute(tool_call)
        #     yield response_str + "\n"
    else:
        response_str = response["choices"][0]["message"]["content"]
        tool_call_params = get_llamacpp_func_extra_params(response_str)
        if tool_call_params:
            function_info = tools_map[tool_call_params["name"]]
            response_str = await function_info(*tool_call_params["arguments"])
            if not isinstance(response_str, str):
                response_str = str(response_str)
            yield response_str
        else:
            # if response_str is not str, convert it to str
            if not isinstance(response_str, str):
                response_str = str(response_str)
            yield response_str

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
