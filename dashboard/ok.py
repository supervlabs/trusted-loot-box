
from functools import wraps
import time
from aptos_sdk.account_address import AccountAddress
from dotenv import dotenv_values
import os
import requests
import json

fullnode = "https://fullnode.mainnet.aptoslabs.com"


def memoize(ttl_seconds):
    cache = {}

    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            key = (args, frozenset(kwargs.items()))
            print(key)
            if key in cache:
                value, timestamp = cache[key]
                if ttl_seconds is None or time.time() - timestamp <= ttl_seconds:
                    return value
                else:
                    del cache[key]
            result = func(*args, **kwargs)
            cache[key] = (result, time.time())
            return result
        return wrapper
    return decorator


def get_creator() -> AccountAddress:
    creator = dotenv_values(".env").get("CREATOR")
    if creator is None:
        creator = os.getenv("CREATOR")
    if creator is None:
        raise RuntimeError("CREATOR must be set in.env or environment")
    if not creator.startswith("0x"):
        creator = "0x" + creator
    return AccountAddress.from_str(creator)


def get_named_object_address(
    creator: AccountAddress, names: list[str], separator: str = "::"
) -> AccountAddress:
    return AccountAddress.for_named_object(
        creator=creator, seed=separator.join(names).encode()
    )

def get_group_info(package: str, grade: str) -> tuple[str, int, int]:
    group = get_named_object_address(package, [grade])
    response = requests.get(
        f"{fullnode}/v1/accounts/{group}/resource/{package}::gacha_item::GachaItemGroup",
        headers={"Accept": "application/json"},
    )
    group_info = response.json()
    start = int(group_info["data"]["start_index"])
    end = int(group_info["data"]["end_index"])
    group = str(group_info["data"]["group"])
    print(f"{grade}: {start} - {end}")
    return group, start, end


def get_item_count(package: str, item_group: str, item_index: int) -> tuple[str, int]:
    item = get_named_object_address(package, [item_group, str(item_index)])
    response = requests.get(
        f"{fullnode}/v1/accounts/{item}/resource/{package}::gacha_item::GachaItem",
        headers={"Accept": "application/json"},
    )
    item_info = response.json()
    response = requests.get(
        f"{fullnode}/v1/accounts/{item}/resource/{package}::gacha_item::GachaItemCount",
        headers={"Accept": "application/json"},
    )
    item_count = response.json()
    name = item_info["data"]["name"]
    count = int(item_count["data"]["count"])
    return name, count


package = get_named_object_address(get_creator(), ["supervlabs"])
print(package)
grades = [
    "sidekick/legendary",
    "sidekick/epic",
    "sidekick/rare",
    "sidekick/uncommon",
    "sidekick/common",
]

counts = dict()
counts_per_grade = dict()
for grade in grades:
    group, start, end = get_group_info(package, grade)
    for i in range(int(start), int(end)):
        name, count = get_item_count(package, group, i)
        if counts.get(group) is None:
            counts[group] = dict()
        if counts[group].get(name) is None:
            counts[group][name] = 0
        counts[group][name] += count
        if counts_per_grade.get(grade) is None:
            counts_per_grade[grade] = 0
        counts_per_grade[grade] += count
json_data = json.dumps(counts, indent=2)
print(json_data)

json_data = json.dumps(counts_per_grade, indent=2)
print(json_data)
