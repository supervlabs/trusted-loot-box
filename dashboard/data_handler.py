import os

import pandas as pd
import requests
import streamlit as st
from dotenv import load_dotenv

GRADES = ("Common", "Uncommon", "Rare", "Epic", "Legendary")
PROBABILITIES = (1 - (0.3 + 0.05 + 0.008 + 0.001), 0.3, 0.05, 0.008, 0.001)
assert len(GRADES) == len(PROBABILITIES)
assert sum(PROBABILITIES) == 1

load_dotenv()
API_URL = os.getenv("API_URL", "")
if not API_URL:
    raise ValueError("API_URL is not set in .env file or in environment variable.")
TTL = int(os.getenv("TTL", 15))


@st.cache_data(ttl=TTL, show_spinner=False)
def get_count() -> pd.DataFrame:
    counts = requests.get(API_URL + "/count").json()
    counts = {k: counts[k] for k in GRADES}
    result = pd.DataFrame.from_dict(counts, orient="index", columns=["Count"])
    return result


@st.cache_data(ttl=TTL, show_spinner=False)
def get_onehot_cumsum(limit: int = 1000) -> pd.DataFrame:
    logs = requests.get(
        API_URL + "/onehot", params={"limit": limit, "cumsum": True}
    ).json()
    df = pd.DataFrame(logs)
    df["skey"] = pd.to_datetime(df["skey"], format="ISO8601")
    return df


@st.cache_data(ttl=TTL, show_spinner=False)
def get_onehot(limit: int = 1000) -> pd.DataFrame:
    logs = requests.get(API_URL + "/onehot", params={"limit": limit}).json()
    df = pd.DataFrame(logs)
    df["skey"] = pd.to_datetime(df["skey"], format="ISO8601")
    return df


@st.cache_data(ttl=TTL, show_spinner=False)
def get_minting_logs(limit: int = 1000, offset: int = 0) -> pd.DataFrame:
    logs = requests.get(
        API_URL + "/items", params={"limit": limit, "offset": offset}
    ).json()
    df = pd.DataFrame(logs)
    df["created_at"] = pd.to_datetime(df["created_at"], format="ISO8601")
    df["skey"] = pd.to_datetime(df["skey"], format="ISO8601")
    return df
