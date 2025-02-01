import os
from dotenv import load_dotenv

load_dotenv()
aoai_key = os.environ["AZURE_OPENAI_KEY"] if os.environ.get("AZURE_OPENAI_KEY") is not None else None
aoai_chat_endpoint = os.environ["AZURE_OPENAI_CHAT_ENDPOINT"] if os.environ.get("AZURE_OPENAI_CHAT_ENDPOINT") is not None else None
aoai_vision_endpoint = os.environ["AZURE_OPENAI_VISION_ENDPOINT"] if os.environ.get("AZURE_OPENAI_VISION_ENDPOINT") is not None else None
ai_speech_service_key = os.environ["AZURE_AI_SPEECH_SERVICE_KEY"] if os.environ.get("AZURE_AI_SPEECH_SERVICE_KEY") is not None else None
ai_speech_service_region = os.environ["AZURE_AI_SPEECH_SERVICE_REGION"] if os.environ.get("AZURE_AI_SPEECH_SERVICE_REGION") is not None else None
weather_api_key = os.environ["WEATHER_API_KEY"] if os.environ.get("WEATHER_API_KEY") is not None else None
bing_api_key = os.environ["BING_API_KEY"] if os.environ.get("BING_API_KEY") is not None else None

chat_model_llamacpp = os.environ["CHAT_MODEL_LLAMACPP"] if os.environ.get("CHAT_MODEL_LLAMACPP") is not None else None
vision_model_llamacpp = os.environ["VISION_MODEL_LLAMACPP"] if os.environ.get("VISION_MODEL_LLAMACPP") is not None else None
