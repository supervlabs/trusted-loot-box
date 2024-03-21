import pandas as pd
import streamlit as st
from fake_data import get_fake_rewards

GRADES = ("Common", "Uncommon", "Rare", "Epic", "Legendary")
PROBABILITIES = (1 - (0.3 + 0.05 + 0.008 + 0.0001), 0.3, 0.05, 0.008, 0.0001)
assert len(GRADES) == len(PROBABILITIES)
assert sum(PROBABILITIES) == 1


@st.cache_data(ttl=10)
def get_rewards_data(since: str, n: int = 10, seed: int | None = None) -> pd.DataFrame:
    # TODO: Get real data from API

    rewards_data = get_fake_rewards(since=since, n=n, seed=seed)
    df = pd.DataFrame(
        rewards_data,
        columns=("datetime", "Common", "Uncommon", "Rare", "Epic", "Legendary"),
    )
    df["datetime"] = pd.to_datetime(df["datetime"], format="%Y-%m-%dT%H:%M:%SZ")

    return df


def convert_json_to_df(json_dicts: list[dict]) -> pd.DataFrame:
    selected_columns = (
        "created_at",
        "grade",
        "item_name",
        "total_minted",
        "token_data_id",
    )
    selected_json_dicts = [
        {k: v for k, v in d.items() if k in selected_columns} for d in json_dicts
    ]
    df = pd.DataFrame(selected_json_dicts)
    df["created_at"] = pd.to_datetime(df["created_at"], format="%Y-%m-%dT%H:%M:%S.%fZ")
    return df


def one_hot_encode(grades_series: pd.Series) -> pd.DataFrame:
    placeholder = pd.Series(list(GRADES))
    df = pd.concat([grades_series, placeholder])
    one_hot = pd.get_dummies(df, dtype=int)
    one_hot = one_hot[list(GRADES)][: -len(placeholder)]  # Drop the placeholder
    return one_hot
