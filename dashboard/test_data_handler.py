import pandas as pd
from data_handler import convert_json_to_df, get_rewards_data, one_hot_encode


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


def test_json_to_df():
    json_dicts = [
        {
            "created_at": "2024-03-19T06:20:20.673Z",
            "grade": "Uncommon",
            "gkey": "sidekick-2024-03-19",
            "selected_round": "0",
            "group": "sidekick",
            "skey": "2024-03-19T06:20:19.840Z-13",
            "updated_at": "2024-03-19T06:20:20.673Z",
            "item_name": "Bruh",
            "item_group": "sidekick/uncommon",
            "total_minted": "13",
            "current_round": "0",
            "token_data_id": "0x1571a2ef6228d78873a44a18f1d5f720735fb882963abbb69467a1052b5cea5a",
            "item_index": "13",
            "token_name": "Bruh #1",
            "item_minted": "1",
            "txn_hash": "0xc2c36385bbdd3c4a16333048b99221ed9d5fbe47498bf0ec60412fc73fc62b8c",
        },
        {
            "created_at": "2024-03-19T06:48:39.226Z",
            "grade": "Common",
            "gkey": "sidekick-2024-03-19",
            "selected_round": "0",
            "group": "sidekick",
            "skey": "2024-03-19T06:48:38.841Z-14",
            "updated_at": "2024-03-19T06:48:39.226Z",
            "item_name": "Poki",
            "item_group": "sidekick/common",
            "total_minted": "14",
            "current_round": "0",
            "token_data_id": "0xae5ef61e4a7e1b411d26e517a6f2e2a388a57d862252b2b0bb24d3ac4718cb56",
            "item_index": "6",
            "token_name": "Poki #2",
            "item_minted": "2",
            "txn_hash": "0x096fe25e070c34349ca7a10bb2f756efb9adc3590df2050c255011f2137bb771",
        },
        {
            "created_at": "2024-03-19T07:25:09.284Z",
            "grade": "Uncommon",
            "gkey": "sidekick-2024-03-19",
            "selected_round": "0",
            "group": "sidekick",
            "skey": "2024-03-19T07:25:07.014Z-15",
            "updated_at": "2024-03-19T07:25:09.284Z",
            "item_name": "Gentlepeng",
            "item_group": "sidekick/uncommon",
            "total_minted": "15",
            "current_round": "0",
            "token_data_id": "0xc8313afe9febd1c7ae529a463bf31a842a3fec40a522a9843e9aea5bdef00d49",
            "item_index": "12",
            "token_name": "Gentlepeng #1",
            "item_minted": "1",
            "txn_hash": "0x6f4eb236a709193594b434940589af43940cbb2f353f4397a2586a15e7dff85e",
        },
    ]

    df = convert_json_to_df(json_dicts)

    assert df["created_at"].dtype == "datetime64[ns]"
    assert df["created_at"].is_monotonic_increasing
    assert df.shape == (3, 5)
    assert df.columns.tolist() == [
        "created_at",
        "grade",
        "item_name",
        "total_minted",
        "token_data_id",
    ]
    assert df["grade"].tolist() == ["Uncommon", "Common", "Uncommon"]
    assert df["item_name"].tolist() == ["Bruh", "Poki", "Gentlepeng"]
    assert df["total_minted"].tolist() == ["13", "14", "15"]
    assert df["token_data_id"].tolist() == [
        "0x1571a2ef6228d78873a44a18f1d5f720735fb882963abbb69467a1052b5cea5a",
        "0xae5ef61e4a7e1b411d26e517a6f2e2a388a57d862252b2b0bb24d3ac4718cb56",
        "0xc8313afe9febd1c7ae529a463bf31a842a3fec40a522a9843e9aea5bdef00d49",
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
