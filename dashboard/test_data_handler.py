import os

import pandas as pd
from data_handler import (
    convert_json_to_df,
    get_api_url,
    get_dataframe,
    get_rewards_data,
    one_hot_encode,
)


def test_get_rewards_data():
    df = get_rewards_data("2024-01-01T00:00:00Z", 100, seed=314)
    assert df.shape == (100, 6)
    assert df.columns.tolist() == [
        "datetime",
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
    ]
    assert df["datetime"].dtype == "datetime64[ns]"
    assert df["Legendary"].sum() == 0
    assert df["Epic"].sum() == 0
    assert df["Rare"].sum() == 4
    assert df["Uncommon"].sum() == 14
    assert df["Common"].sum() == 82
    assert df["datetime"].is_monotonic_increasing


TEST_JSON_DICT = [
    {
        "created_at": "2024-03-21T05:42:22.303Z",
        "grade": "Uncommon",
        "gkey": "sidekick-2024-03-21",
        "selected_round": "0",
        "group": "sidekick",
        "skey": "2024-03-21T05:42:21.540Z-undefined",
        "updated_at": "2024-03-21T05:42:22.303Z",
        "item_name": "Gentlepeng",
        "item_group": "sidekick/uncommon",
        "current_round": "0",
        "item_index": "12",
        "item_minted": "1",
        "txn_hash": "0x1dd9e37675efe20ff2d65b6faddfde3ab8b94646947346ba3ad7cd77d619bc24",
    },
    {
        "created_at": "2024-03-21T05:50:11.144Z",
        "grade": "Common",
        "gkey": "sidekick-2024-03-21",
        "selected_round": "0",
        "group": "sidekick",
        "skey": "2024-03-21T05:50:10.598Z-undefined",
        "updated_at": "2024-03-21T05:50:11.144Z",
        "item_name": "Monkin",
        "item_group": "sidekick/common",
        "current_round": "0",
        "item_index": "11",
        "item_minted": "2",
        "txn_hash": "0x29cdb96ba926f6aa70c288a81b546fe8c0ae1038e317a443103ff29c6fa4946f",
    },
    {
        "created_at": "2024-03-21T06:05:49.164Z",
        "grade": "Common",
        "gkey": "sidekick-2024-03-21",
        "selected_round": "0",
        "group": "sidekick",
        "skey": "2024-03-21T06:05:48.584Z-undefined",
        "updated_at": "2024-03-21T06:05:49.164Z",
        "item_name": "Rubicle",
        "item_group": "sidekick/common",
        "current_round": "0",
        "item_index": "8",
        "item_minted": "1",
        "txn_hash": "0x71908206190323f43fbd3f3c8f90711ef07c488cd6de9ab0446238cd05b59b76",
    },
    {
        "created_at": "2024-03-21T06:20:08.072Z",
        "grade": "Common",
        "gkey": "sidekick-2024-03-21",
        "selected_round": "0",
        "group": "sidekick",
        "skey": "2024-03-21T06:20:07.646Z-undefined",
        "updated_at": "2024-03-21T06:20:08.072Z",
        "item_name": "Monkin",
        "item_group": "sidekick/common",
        "current_round": "0",
        "item_index": "11",
        "item_minted": "4",
        "txn_hash": "0x50d4bb94ea4a40ca7cff97c91f3bf06f6100558429d456be6b2f58311327e0f6",
    },
]


def test_json_to_df():
    df = convert_json_to_df(TEST_JSON_DICT)

    assert df["created_at"].dtype == "datetime64[ns]"
    assert df["created_at"].is_monotonic_increasing
    assert df.shape == (4, 4)
    assert df.columns.tolist() == [
        "created_at",
        "grade",
        "item_name",
        "txn_hash",
    ]
    assert df["grade"].tolist() == ["Uncommon", "Common", "Common", "Common"]
    assert df["item_name"].tolist() == ["Gentlepeng", "Monkin", "Rubicle", "Monkin"]
    assert df["txn_hash"].tolist() == [
        "0x1dd9e37675efe20ff2d65b6faddfde3ab8b94646947346ba3ad7cd77d619bc24",
        "0x29cdb96ba926f6aa70c288a81b546fe8c0ae1038e317a443103ff29c6fa4946f",
        "0x71908206190323f43fbd3f3c8f90711ef07c488cd6de9ab0446238cd05b59b76",
        "0x50d4bb94ea4a40ca7cff97c91f3bf06f6100558429d456be6b2f58311327e0f6",
    ]


def test_one_hot_encode():
    df = pd.DataFrame(
        {
            "grade": [
                "Common",
                "Epic",
                "Uncommon",
                "Rare",
                "Rare",
                "Epic",
                "Legendary",
            ],
        }
    )

    df_encoded = one_hot_encode(df["grade"])

    assert df_encoded.shape == (7, 5)
    assert df_encoded.columns.tolist() == [
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
    ]
    assert df_encoded["Common"].tolist() == [1, 0, 0, 0, 0, 0, 0]
    assert df_encoded["Uncommon"].tolist() == [0, 0, 1, 0, 0, 0, 0]
    assert df_encoded["Rare"].tolist() == [0, 0, 0, 1, 1, 0, 0]
    assert df_encoded["Epic"].tolist() == [0, 1, 0, 0, 0, 1, 0]
    assert df_encoded["Legendary"].tolist() == [0, 0, 0, 0, 0, 0, 1]


def test_one_hot_encode_with_missing_grades():
    df = pd.DataFrame(
        {
            "grade": [
                "Common",
                "Epic",
                "Uncommon",
                "Rare",
                "Rare",
                "Epic",
                "Common",
                "Uncommon",
                "Rare",
                "Epic",
            ],
        }
    )

    df_encoded = one_hot_encode(df["grade"])

    assert df_encoded.shape == (10, 5)
    assert df_encoded.columns.tolist() == [
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
    ]
    assert df_encoded["Common"].tolist() == [1, 0, 0, 0, 0, 0, 1, 0, 0, 0]
    assert df_encoded["Uncommon"].tolist() == [0, 0, 1, 0, 0, 0, 0, 1, 0, 0]
    assert df_encoded["Rare"].tolist() == [0, 0, 0, 1, 1, 0, 0, 0, 1, 0]
    assert df_encoded["Epic"].tolist() == [0, 1, 0, 0, 0, 1, 0, 0, 0, 1]
    assert df_encoded["Legendary"].tolist() == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]


def test_get_dataframe():
    df = get_dataframe(TEST_JSON_DICT)

    assert df.shape == (4, 9)
    assert df.columns.tolist() == [
        "created_at",
        "grade",
        "item_name",
        "txn_hash",
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
    ]
    assert df["Common"].tolist() == [0, 1, 1, 1]
    assert df["Uncommon"].tolist() == [1, 0, 0, 0]
    assert df["Rare"].tolist() == [0, 0, 0, 0]
    assert df["Epic"].tolist() == [0, 0, 0, 0]
    assert df["Legendary"].tolist() == [0, 0, 0, 0]


def test_get_api_url():
    os.environ["API_URL"] = "http://test.com/backend/web3/gacha/sidekick"
    actual = get_api_url()
    assert (
        actual
        == "http://test.com/backend/web3/gacha/sidekick?since=2024-01-01T00%3A00%3A00Z"
    )
    os.environ.pop("API_URL")

    assert os.environ.get("API_URL") is None
    actual = get_api_url()
    assert (
        actual
        == "https://randomhack.supervlabs.net/backend/web3/gacha/sidekick?since=2024-01-01T00%3A00%3A00Z"
    )
