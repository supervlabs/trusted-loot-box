from datetime import datetime, timedelta

import pandas as pd
import plotly.express as px
import streamlit as st
from data_handler import (
    GRADES,
    PROBABILITIES,
    get_reward_counts,
    get_rewards_data,
    rewards_fetch_limit,
)
from streamlit_autorefresh import st_autorefresh

st.set_page_config(
    page_title="Trusted Loot Box",
    page_icon="🎲",
    layout="wide",
    initial_sidebar_state="auto",
    menu_items={
        "Get Help": "mailto:cs@supervlabs.io",
        "Report a bug": "mailto:cs@supervlabs.io",
        "About": "This is a dashboard for Trusted Loot Box by [Supervillain Labs](https://supervlabs.io/)",
    },
)

colors = ["#ffffff", "#a1ce5a", "#53b4dd", "#bc64ea", "#fedb50"]


def show_rewards_probabilities(col):
    # TODO: Get real rewards table from api
    reward_grades = GRADES[::-1]
    reward_probabilities = PROBABILITIES[::-1]
    rewards_table = pd.DataFrame(
        {"Rewards": reward_grades, "Probabilities": reward_probabilities}
    )
    rewards_table.set_index("Rewards", inplace=True)

    with col:
        st.markdown(
            "**Reward Probabilities:** What are the chances of getting each reward?"
        )
        st.data_editor(
            rewards_table,
            column_config={
                "Rewards": st.column_config.TextColumn(disabled=True),
                "Probabilities": st.column_config.NumberColumn(
                    format="%.4f", disabled=True
                ),
            },
        )


def get_next(since: str | None = None) -> str:
    if since is None:
        three_days_ago = datetime.now() - timedelta(days=7)
        return three_days_ago.isoformat().rsplit("Z", 1)[0][:-1] + "@"
    return since.rsplit("Z", 1)[0][:-1] + "@"


def get_rewards() -> pd.DataFrame:
    if "last_updated" not in st.session_state:
        st.session_state.last_updated = get_next(None)
    if "df" not in st.session_state:
        st.session_state.df = pd.DataFrame()
    while True:
        since = st.session_state.last_updated
        new_df = get_rewards_data(since)
        if (new_df is None) or new_df.empty:
            break
        _df = pd.concat([st.session_state.df, new_df], ignore_index=True)
        _df.drop_duplicates(subset="txn_hash", keep="last", inplace=True)
        _df.reset_index(drop=True, inplace=True)
        if len(_df) > rewards_fetch_limit:
            _df = _df.iloc[-rewards_fetch_limit:, :]
        st.session_state.df = _df
        latest_datetime = _df["skey"].max()
        st.session_state.last_updated = get_next(latest_datetime)
    return st.session_state.df


def get_next_reward_counts(since: str | None = None) -> str:
    if since is None:
        return "2024-03-15T00:00:00Z"
    return since.rsplit("Z", 1)[0][:-1] + "@"


def get_all_reward_counts() -> dict[str, int]:
    if "last_updated_time" not in st.session_state:
        st.session_state.last_updated_time = get_next_reward_counts(None)
    if "reward_counts" not in st.session_state:
        rewards = ["Total Trials"] + list(GRADES)
        st.session_state.reward_counts = dict.fromkeys(rewards, 0)
    while True:
        since = st.session_state.last_updated_time
        reward_counts, latest_update = get_reward_counts(since)
        st.session_state.last_updated_time = get_next_reward_counts(latest_update)
        if reward_counts is None:
            break
        for k, v in reward_counts.items():
            st.session_state.reward_counts[k] += v
    return st.session_state.reward_counts


st.title("Trusted Loot Box - Dashboard")

reward_counts = get_all_reward_counts()
names = ["Total Trials"] + list(GRADES)
values = [reward_counts[name] for name in names]
df = get_rewards()

with st.container():
    left, right = st.columns(2)
    with left:
        # Show Metrics
        n_metrics = len(GRADES) + 1
        st.markdown("**Metrics:** How many rewards have been distributed by grades?")
        for i, col in enumerate(st.columns(n_metrics + 1)):
            if i == n_metrics - 1:
                # Add a rainbow star for the last metric which is the rarest
                col.metric(label=f":rainbow[⭐️ {names[i]}]", value=values[i])
            elif i == n_metrics:
                continue
            else:
                col.metric(label=names[i], value=values[i])

    with right:
        show_rewards_probabilities(right)

left, right = st.columns(2)

with left:
    # Show pie chart for Rewards
    fig = px.pie(
        values=values[1:],
        names=names[1:],
        title="Rewards Distribution",
        color_discrete_sequence=colors,
    )
    st.plotly_chart(fig)


with right:
    # Show Time Series for All Rewards
    fig = px.line(
        df.set_index("created_at").iloc[:, 6:].cumsum(),
        title="Rewards Time Series",
        color_discrete_sequence=colors,
    ).update_layout(
        xaxis_title="Date",
        yaxis_title="Cumulative Count",
        legend_title="Rewards",
    )
    st.plotly_chart(fig)

with right:
    # Show Time Series for the Rarest Reward and confidence interval
    fig = px.line(
        df.set_index("created_at").iloc[:, 6:].cumsum(),
        y="Legendary",
        title="Legendary Time Series",
        color_discrete_sequence=colors[-1:],
    ).update_layout(xaxis_title="Date", yaxis_title="Cumulative Count")
    st.plotly_chart(fig)

with left:
    # Show Heatmap for Rewards vs. Trials
    df_heatmap = df.iloc[:, 7:].T
    df_heatmap = df_heatmap.reindex(
        index=df_heatmap.index[::-1]
    )  # Reverse the order of rows

    fig = px.imshow(
        df_heatmap,
        x=df.index + 1,
        title="Rewards at Each Trial",
        labels={"x": "# Trials", "y": "Rewards"},
        color_continuous_scale=["white", "blue"],
    ).update_layout(coloraxis_showscale=False)
    st.plotly_chart(fig)


# Show the trial table
df_for_table = df.copy().iloc[-100:, :7]
df_for_table.set_index("total_minted", inplace=True)
df_for_table.index.name = "# Trials"


def make_reward_link(token_data_id):
    url = f"https://explorer.aptoslabs.com/token/{token_data_id}/0?network=randomnet"
    return url


def make_dice_link(txn_hash):
    url = f"https://explorer.aptoslabs.com/txn/{txn_hash}/userTxnOverview?network=randomnet"
    return url


df_for_table["link_to_reward"] = df_for_table["token_data_id"].apply(make_reward_link)
df_for_table["link"] = df_for_table["txn_hash"].apply(make_dice_link)

df_for_table.drop(columns=["token_data_id", "txn_hash", "skey"], inplace=True)

st.markdown("**Trials Table:** The list of Rewards for each trial")
st.data_editor(
    df_for_table[::-1],
    column_config={
        "created_at": st.column_config.DatetimeColumn(
            "DateTime (UTC)", format="YYYY-MM-DD HH:mm:ss.SSS"
        ),
        "grade": st.column_config.TextColumn("Grade"),
        "item_name": st.column_config.TextColumn("Item Name", width=150),
        "link_to_reward": st.column_config.LinkColumn(
            "Reward Link", display_text="🔗 Link to Aptos Explorer"
        ),
        "txn_hash": st.column_config.TextColumn("Txn Hash"),
        "link": st.column_config.LinkColumn(
            "Dice Link",
            display_text="🔗 Link to Aptos Explorer",
        ),
    },
    disabled=True,
)

st_autorefresh(interval=15 * 1000, limit=10, key="trusted_loot_box")
