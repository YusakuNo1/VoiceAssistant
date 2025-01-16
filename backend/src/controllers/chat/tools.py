from enum import Enum
import dataclasses
import json
import requests
from src.config.env import weather_api_key


@dataclasses.dataclass
class Platform(Enum):
    IOS = "ios"
    WEB = "web"

@dataclasses.dataclass
class ActionType(Enum):
    GET_WEATHER = "get_weather"
    CHANGE_VOLUME = "change_volume"
    OPEN_MAP = "open_map"
    OPEN_BROWSER = "open_browser"

@dataclasses.dataclass
class Action:
    platform: Platform
    actionType: ActionType
    data: dict[str, any]


async def get_weather(name: str) -> str:
    """find the location name from the command for weather, and then convert to a JSON string with Action format

    :param name (str): The name of the location from the command for weather
    :rtype: str

    :return: the action command as a JSON string
    :rtype: str
    """
    url = f'http://api.weatherapi.com/v1/current.json?key={weather_api_key}&q={name}'

    # Make the request
    response = requests.get(url)

    # Check if the request was successful
    if response.status_code == 200:
        data = response.json()
        data = data['current']
        data['name'] = name
        action = Action(platform=Platform.IOS.value, actionType=ActionType.GET_WEATHER.value, data=data)
        return json.dumps(dataclasses.asdict(action))
    else:
        print(f"Failed to retrieve data: {response.status_code}")


async def change_volume(volume: int) -> str:
    """Convert the command to volume value in int, and then convert to a JSON string with Action format

    :param volume (int): The volume value from the command
    :rtype: int

    :return: the action command as a JSON string
    :rtype: str
    """
    action = Action(platform=Platform.IOS.value, actionType=ActionType.CHANGE_VOLUME.value, data={"volume": volume})
    return json.dumps(dataclasses.asdict(action))


async def open_browser(name: str, url: str) -> str:
    """When the user ask for open website for a company or organization, get the URL, and then convert to a JSON string with Action format

    :param name (str): The name of the company or organization from the command
    :rtype: str

    :param url (str): The url value from the command
    :rtype: str

    :return: the action command as a JSON string
    :rtype: str
    """
    data = { "name": name, "url": url }
    action = Action(platform=Platform.IOS.value, actionType=ActionType.OPEN_BROWSER.value, data=data)
    return json.dumps(dataclasses.asdict(action))


async def open_map(name: str, latitude: float, longitude: float) -> str:
    """When the user ask for open map for a location, get the latitude and longitude, and then convert to a JSON string with Action format

    :param name (str): The name of the location from the command
    :rtype: str

    :param latitude (float): The latitude value from the command
    :rtype: float

    :param longitude (float): The longitude value from the command
    :rtype: float

    :return: the action command as a JSON string
    :rtype: str
    """
    data = { "name": name, "latitude": latitude, "longitude": longitude }
    action = Action(platform=Platform.IOS.value, actionType=ActionType.OPEN_MAP.value, data=data)
    return json.dumps(dataclasses.asdict(action))
