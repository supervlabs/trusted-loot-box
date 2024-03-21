import os
from urllib.parse import urlencode, urlunparse

import pandas as pd
import streamlit as st
from dotenv import dotenv_values
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
        "txn_hash",
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


def get_dataframe(json_dicts: list[dict]) -> pd.DataFrame:
    df = convert_json_to_df(json_dicts)
    df_encoded = one_hot_encode(df["grade"])
    df = pd.concat([df, df_encoded], axis=1)
    return df


def get_api_url(api_url: str | None = None, since_date: str | None = None) -> str:
    if since_date is None:
        since_date = "2024-01-01T00:00:00Z"

    if api_url is None:
        if (api_url := os.getenv("API_URL")) is None:
            api_url = dotenv_values(".env").get("API_URL")

    if api_url is None:
        raise ValueError("API_URL is not set in .env file or in environment variable.")

    query_params = {"since": since_date}
    query_string = urlencode(query_params)
    return urlunparse(("", "", api_url, "", query_string, ""))
