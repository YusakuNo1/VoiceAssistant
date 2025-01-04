from dataclasses import dataclass

@dataclass
class AppConfig:
    language: str # e.g. en-us. Wiki: https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes
    recognition_timeout: str # Timeout for speech recognition in milliseconds
