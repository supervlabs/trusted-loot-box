import pandas as pd
import streamlit as st
from fake_data import get_fake_rewards


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
