import pandas as pd
import streamlit as st
from fake_data import get_fake_rewards


@st.cache_data(ttl=10)
def get_rewards_data(since: str, n: int = 10) -> pd.DataFrame:
    # TODO: Get real data from API

    rewards_data = get_fake_rewards(since=since, n=n, seed=314)
    df = pd.DataFrame(
        rewards_data,
        columns=("datetime", "Common", "Uncommon", "Rare", "Epic", "Legendary"),
    )
    df["datetime"] = pd.to_datetime(df["datetime"], format="%Y-%m-%dT%H:%M:%SZ")

    return df
