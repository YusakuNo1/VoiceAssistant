import time
from fastapi import Request
from fastapi.responses import StreamingResponse
from dataclasses import dataclass
import azure.cognitiveservices.speech as speechsdk
from src.config.app import app
from src.config.env import ai_speech_service_key, ai_speech_service_region
from src.config.app import app_config


async def receive_stream(request: Request):
    # https://github.com/Azure-Samples/cognitive-services-speech-sdk/blob/513c0d8e4370f47dcf241c0682265c2b2fa37db6/samples/python/console/speech_sample.py#L356
    async def createStreamFromPushAudioInputStream():
        audio_input = speechsdk.audio.PushAudioInputStream()
        async for chunk in request.stream():
            print(f"Received chunk: {len(chunk)}")
            if not chunk:
                print("End of stream")
            else:
                audio_input.write(chunk)
        audio_input.close()  # Close the stream to indicate the end of audio data
        audio_config = speechsdk.audio.AudioConfig(stream=audio_input)
        return audio_config
    
    audio_config = await createStreamFromPushAudioInputStream()

    speech_config = speechsdk.SpeechConfig(subscription=ai_speech_service_key, region=ai_speech_service_region)
    speech_config.set_property(speechsdk.PropertyId.Speech_SegmentationSilenceTimeoutMs, app_config.recognition_timeout)
    recognizer = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_config, language=app_config.language)

    done = False

    def stop_cb(evt: speechsdk.SessionEventArgs):
        """callback that signals to stop continuous recognition upon receiving an event `evt`"""
        print('CLOSING on {}'.format(evt))
        nonlocal done
        done = True

    response_map = {}
    def recognized_cb(evt: speechsdk.SpeechRecognitionEventArgs):
        print('RECOGNIZED: {} {}'.format(evt.result.result_id, evt.result.text))
        nonlocal response_map
        response_map[evt.result.result_id] = evt.result.text

    # Connect callbacks to the events fired by the speech recognizer
    recognizer.recognizing.connect(lambda evt: print('RECOGNIZING: {}'.format(evt.result.text)))
    recognizer.recognized.connect(recognized_cb)
    recognizer.session_started.connect(lambda evt: print('SESSION STARTED: {}'.format(evt)))
    recognizer.session_stopped.connect(lambda evt: print('SESSION STOPPED {}'.format(evt)))
    recognizer.canceled.connect(lambda evt: print('CANCELED {}'.format(evt)))
    # Stop continuous recognition on either session stopped or canceled events
    recognizer.session_stopped.connect(stop_cb)
    recognizer.canceled.connect(stop_cb)

    # Start continuous speech recognition
    recognizer.start_continuous_recognition()

    while not done:
        time.sleep(.5)

    recognizer.stop_continuous_recognition()
    response_values = filter(lambda x: len(x) > 0, response_map.values())
    response_text = "\n".join(response_values)
    return response_text


@app.post("/speech/recognize")
async def speech_recognize(request: Request):
    return await receive_stream(request)


@dataclass
class SpeechSynthesizeRequest:
    text: str

@app.post("/speech/synthesize")
async def speech_synthesize(request: SpeechSynthesizeRequest):
    async def generate_speech():
        import azure.cognitiveservices.speech as speechsdk

        speech_config = speechsdk.SpeechConfig(subscription=ai_speech_service_key, region=ai_speech_service_region)
        speech_config.speech_synthesis_voice_name = "en-US-AriaNeural"
        speech_synthesizer = speechsdk.SpeechSynthesizer(
            speech_config=speech_config,
            audio_config=None, # Disable audio output
            auto_detect_source_language_config=speechsdk.languageconfig.AutoDetectSourceLanguageConfig(),
        )

        result = speech_synthesizer.speak_text_async(request.text).get()

        if result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
            yield result.audio_data
        elif result.reason == speechsdk.ResultReason.Canceled:
            cancellation_details = result.cancellation_details
            print("Speech synthesis canceled: {}".format(cancellation_details.reason))
            if cancellation_details.reason == speechsdk.CancellationReason.Error:
                if cancellation_details.error_details:
                    print("Error details: {}".format(cancellation_details.error_details))
            print("Did you update the subscription info?")

    return StreamingResponse(generate_speech(), media_type="application/octet-stream") 


@app.get("/speech")
async def get_sth():
    return "abc"
