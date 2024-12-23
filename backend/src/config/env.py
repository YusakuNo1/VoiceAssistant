import os
from dotenv import load_dotenv

load_dotenv()
aoai_chat_endpoint = os.environ["AZURE_OPENAI_CHAT_ENDPOINT"]
ai_speech_service_key = os.environ["AZURE_AI_SPEECH_SERVICE_KEY"]
ai_speech_service_region = os.environ["AZURE_AI_SPEECH_SERVICE_REGION"]
