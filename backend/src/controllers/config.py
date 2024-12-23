from src.config.app import app
from src.config.env import ai_speech_service_key, ai_speech_service_region


@app.get("/credentials")
async def credentials():
    return {
        "speech": {
            "key": ai_speech_service_key,
            "region": ai_speech_service_region,
        },
    }
