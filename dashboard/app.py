import pandas as pd
import plotly.express as px  # type: ignore
import streamlit as st
from data_handler import (
    GRADES,
    PROBABILITIES,
    TTL,
    get_count,
    get_minting_logs,
    get_onehot,
    get_onehot_cumsum,
)
from streamlit_autorefresh import st_autorefresh  # type: ignore

st.set_page_config(
    page_title="Sidekick Draw",
    page_icon="🎲",
    layout="wide",
    initial_sidebar_state="auto",
    menu_items={
        "Get Help": "mailto:cs@supervlabs.io",
        "Report a bug": "mailto:cs@supervlabs.io",
        "About": "This is a dashboard for Sidekick Draw by [Supervillain Labs](https://supervlabs.io/)",
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
    rewards_table["Probabilities"] = rewards_table["Probabilities"] * 100

    with col:
        st.markdown(
            "**Reward Probabilities:** What are the chances of getting each reward?"
        )
        st.data_editor(
            rewards_table,
            column_config={
                "Rewards": st.column_config.TextColumn(disabled=True),
                "Probabilities": st.column_config.NumberColumn(
                    format="%.1f %%", disabled=True
                ),
            },
        )


st.title("Sidekick Draw - Dashboard")

with st.container():
    left, right = st.columns(2)
    with left:
        # Show Metrics
        df_count = get_count()
        n_trial = int(df_count.sum().iloc[0])
        n_reward_grades = len(df_count)
        names = df_count.index.tolist()
        names = ["Total Trials"] + [n.capitalize() for n in names]
        values: list = [n_trial] + df_count["Count"].tolist()

        n_metrics = n_reward_grades + 1
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
    st.markdown("#### Rewards Time Series")
    limit_time_series = st.slider(
        "How many recent trials to show in Time Series?",
        min_value=100,
        max_value=n_trial,
        value=n_trial,
        step=100,
        key="limit_time_series",
    )

    df_onehot_cumsum = get_onehot_cumsum(limit_time_series)
    df_onehot_cumsum.columns = df_onehot_cumsum.columns.str.capitalize()
    fig = px.line(
        df_onehot_cumsum.set_index("Skey")[
            ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
        ],
        title="Rewards Time Series",
        color_discrete_sequence=colors,
        hover_data={"#trial": df_onehot_cumsum["Total_minted"]},
    ).update_layout(
        xaxis_title="Date",
        yaxis_title="Cumulative Count",
        legend_title="Rewards",
    )
    st.plotly_chart(fig)

with right:
    # Show Time Series for the Rarest Reward and confidence interval
    fig = px.line(
        df_onehot_cumsum.set_index("Skey")["Legendary"],
        y="Legendary",
        title="Legendary Time Series",
        color_discrete_sequence=colors[-1:],
        hover_data={"#trial": df_onehot_cumsum["Total_minted"]},
    ).update_layout(xaxis_title="Date", yaxis_title="Cumulative Count")
    st.plotly_chart(fig)

with left:
    # Show Heatmap for Rewards vs. Trials
    st.markdown("#### Rewards Heatmap")
    limit_heatmap = st.slider(
        "How many recent trials to show in Rewards Heatmap?",
        min_value=100,
        max_value=n_trial,
        value=n_trial // 200 * 100 if n_trial >= 1000 else n_trial,
        step=100,
        key="limit_heatmap",
    )
    df_heatmap = get_onehot(limit_heatmap)
    df_heatmap.set_index("total_minted", inplace=True)
    df_heatmap.columns = df_heatmap.columns.str.capitalize()
    df_heatmap = df_heatmap[["Common", "Uncommon", "Rare", "Epic", "Legendary"]]

    fig = px.imshow(
        df_heatmap.T[::-1],
        title="Rewards at Each Trial",
        labels={"x": "# Trials", "y": "Rewards"},
        color_continuous_scale=["white", "blue"],
    ).update_layout(coloraxis_showscale=False)
    st.plotly_chart(fig)


# Show the trial table

with left:
    st.markdown("#### Trials Table: List of recent Rewards for each trial")
    menu = st.columns((2, 1, 1, 1))
    with menu[3]:
        batch_size = st.selectbox("Page Size", options=[25, 50, 100], index=1)
    with menu[1]:
        grades_with_all = ["All"] + list(GRADES)
        if (grade := st.selectbox("Grade", options=grades_with_all, index=0)) is None:
            grade = "All"
        n_grade = values[grades_with_all.index(grade)]
    with menu[2]:
        if batch_size is None:
            batch_size = 50
        total_pages = (
            int(n_grade / batch_size) + 1 if int(n_grade / batch_size) > 0 else 1
        )
        current_page = st.number_input(
            "Page", min_value=1, max_value=total_pages, step=1
        )
    with menu[0]:
        st.markdown(
            f"Page **{current_page}** of **{total_pages}** / **{grade}** Count: {n_grade}"
        )

    limit_table = batch_size
    offset = int((current_page - 1) * batch_size)
    df_minting_logs = get_minting_logs(limit_table, offset, grade)

    if df_minting_logs.empty:
        st.warning("No data available for the selected grade.")
    else:
        df_minting_logs.set_index("total_minted", inplace=True)
        df_minting_logs.index.name = "# Trials"

        def pad_zero(address):
            # Add a leading zero to make it 66 characters
            # Aptos Explorer requires 66 characters address
            if len(address) == 65:
                address = address[:2] + "0" + address[2:]
            return address

        def make_reward_link(token_data_id):
            token_data_id = pad_zero(token_data_id)
            url = f"https://explorer.aptoslabs.com/token/{token_data_id}/0?network=mainnet"
            return url

        def make_dice_link(txn_hash):
            txn_hash = pad_zero(txn_hash)
            url = f"https://explorer.aptoslabs.com/txn/{txn_hash}/userTxnOverview?network=mainnet"
            return url

        df_minting_logs["link_to_reward"] = df_minting_logs["token_data_id"].apply(
            make_reward_link
        )
        df_minting_logs["link_to_dice"] = df_minting_logs["txn_hash"].apply(
            make_dice_link
        )

        df_minting_logs["item_name"] = df_minting_logs["token_name"]
        df_minting_logs = df_minting_logs[
            ["skey", "grade", "item_name", "link_to_reward", "link_to_dice"]
        ]
        st.data_editor(
            df_minting_logs,
            column_config={
                "skey": st.column_config.DatetimeColumn(
                    "DateTime (UTC)", format="YYYY-MM-DD HH:mm:ss.SSS"
                ),
                "grade": st.column_config.TextColumn("Grade"),
                "item_name": st.column_config.TextColumn("Item Name", width=150),  # type: ignore
                "link_to_reward": st.column_config.LinkColumn(
                    "Reward Link", display_text="🔗 Link to Aptos Explorer"
                ),
                "link_to_dice": st.column_config.LinkColumn(
                    "Dice Link",
                    display_text="🔗 Link to Aptos Explorer",
                ),
            },
            disabled=True,
        )


# Auto refresh the page
refresh_interval_seconds = TTL
refresh_maintaining_minutes = 30
refresh_limit = int(refresh_maintaining_minutes * 60 / refresh_interval_seconds)
st_autorefresh(
    interval=refresh_interval_seconds * 1000,
    limit=refresh_limit,
    key="trusted_loot_box",
)
