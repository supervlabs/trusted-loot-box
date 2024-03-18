from data_handler import get_rewards_data


def test_get_rewards_data():
    df = get_rewards_data("2024-01-01T00:00:00Z", 100)
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
    assert df["Epic"].sum() == 4
    assert df["Rare"].sum() == 3
    assert df["Uncommon"].sum() == 17
    assert df["Common"].sum() == 76
    assert df["datetime"].is_monotonic_increasing
