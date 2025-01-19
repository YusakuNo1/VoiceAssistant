import prompty
from azure.ai.inference.prompts import PromptTemplate
from src.controllers.chat.types import Message


cached_prompt_templates = {}

def get_endpoint(prompty_file: str):
    prompt_template = _get_prompt_template(prompty_file)
    return f"{prompt_template.prompty.model.configuration['azure_endpoint']}/openai/deployments/{prompt_template.prompty.model.configuration['azure_deployment']}"

def get_messages(prompty_file: str):
    prompt_template = _get_prompt_template(prompty_file)
    messages_json = prompt_template.create_messages()
    messages = []
    for message_json in messages_json:
        messages.append(Message(role=message_json["role"], content=message_json["content"]))
    return messages

def _get_prompt_template(prompty_file: str) -> PromptTemplate:
    if not cached_prompt_templates.get(prompty_file):
        prompt_template = PromptTemplate.from_prompty(file_path=prompty_file)
        cached_prompt_templates[prompty_file] = prompt_template
    prompt_template = cached_prompt_templates[prompty_file]
    return prompt_template
