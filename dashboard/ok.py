from aptos_sdk.account_address import AccountAddress
from dotenv import dotenv_values
import os
import requests

fullnode = "https://fullnode.mainnet.aptoslabs.com"

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

for grade in grades:
    group = get_named_object_address(package, [grade])
    response = requests.get(
        f"{fullnode}/v1/accounts/{group}/resource/{package}::gacha_item::GachaItemGroup",
        headers={"Accept": "application/json"},
    )
    group_info = response.json()
    start = group_info["data"]["start_index"]
    end = group_info["data"]["end_index"]
    group = group_info["data"]["group"]
    print(f"{grade}: {start} - {end}")
    for i in range(int(start), int(end)+ 1):
        item = get_named_object_address(package, [group, str(i)])
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
        count = item_count["data"]["count"]
        if counts[group] is None:
            counts[group] = {
                "name": count
            }


        print(group, item_info["data"]["index"], item_info["data"]["name"], item_count["data"]["count"])
        
        
        
        
