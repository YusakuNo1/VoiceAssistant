from enum import Enum
import dataclasses
import json


@dataclasses.dataclass
class Platform(Enum):
    IOS = "ios"
    WEB = "web"

@dataclasses.dataclass
class ActionType(Enum):
    GET_WEATHER = "get_weather"
    CHANGE_VOLUME = "change_volume"
    OPEN_BROWSER = "open_browser"

@dataclasses.dataclass
class Action:
    platform: Platform
    actionType: ActionType
    data: dict[str, any]


async def change_volume(volume: int) -> str:
    """Convert the command to volume value in int, and then convert to a JSON string with Action format

    :param volume (int): The volume value from the command
    :rtype: int

    :return: the action command as a JSON string
    :rtype: str
    """
    action = Action(platform=Platform.IOS.value, actionType=ActionType.CHANGE_VOLUME.value, data={"volume": volume})
    return json.dumps(dataclasses.asdict(action))
