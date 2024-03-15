import pandas as pd

from fake_data import get_fake_rewards


def get_rewards_data(n: int = 10) -> pd.DataFrame:
    # TODO: Get real data from API

    rewards_data = get_fake_rewards(n=n, seed=314)
    df = pd.DataFrame(
        rewards_data,
        columns=("datetime", "Common", "Uncommon", "Rare", "Epic", "Legendary"),
    )
    df["datetime"] = pd.to_datetime(df["datetime"], format="%Y-%m-%dT%H:%M:%SZ")

    return df
