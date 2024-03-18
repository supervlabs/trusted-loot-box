import pandas as pd
import plotly.express as px
import streamlit as st
from data_handler import get_rewards_data

st.set_page_config(
    page_title="Trusted Loot Box",
    page_icon="🎲",
    layout="wide",
    initial_sidebar_state="auto",
)

st.title("Trusted Loot Box - Dashboard")

if st.button("Click! to Refresh Data"):
    st.rerun()

if "last_updated" not in st.session_state:
    st.session_state.last_updated = "2024-01-01T00:00:00Z"

if "df" not in st.session_state:
    st.session_state.df = pd.DataFrame()

new_df = get_rewards_data(since=st.session_state.last_updated, n=1000)
df = pd.concat([st.session_state.df, new_df], ignore_index=True)

st.session_state.df = df
latest_datetime = df["datetime"].max().isoformat() + "Z"
st.session_state.last_updated = latest_datetime

# Show Metrics
df_count = df.iloc[:, 1:].sum()
n_trial = df_count.sum()
n_reward_grades = len(df_count)
names = df_count.index.tolist()
names = ["Total Trials"] + [n.capitalize() for n in names]
values = [n_trial] + df_count.tolist()

n_metrics = n_reward_grades + 1
st.markdown("**Metrics:** How many rewards have been distributed by grades?")
for i, col in enumerate(st.columns([1] * n_metrics + [7])):
    if i == n_metrics:
        # Skip the last column which is for the plot
        continue
    elif i == n_metrics - 1:
        # Add a rainbow star for the last metric which is the rarest
        col.metric(label=f":rainbow[⭐️ {names[i]}]", value=values[i])
    else:
        col.metric(label=names[i], value=values[i])


left, right = st.columns(2)

with left:
    # Show pie chart for Rewards
    fig = px.pie(
        values=values[1:],
        names=names[1:],
        title="Rewards Distribution",
    )
    st.plotly_chart(fig)

with right:
    # Show Time Series for All Rewards
    fig = px.line(
        df.set_index("datetime").cumsum(), title="Rewards Time Series"
    ).update_layout(
        xaxis_title="Date",
        yaxis_title="Cumulative Count",
        legend_title="Rewards",
    )
    st.plotly_chart(fig)

with right:
    # Show Time Series for the Rarest Reward and confidence interval
    fig = px.line(
        df.set_index("datetime").cumsum(), y="Legendary", title="Legendary Time Series"
    ).update_layout(xaxis_title="Date", yaxis_title="Cumulative Count")
    st.plotly_chart(fig)

with left:
    # Show Heatmap for Rewards vs. Trials
    df_heatmap = df.iloc[:, 1:].T
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

if st.button("Click to Refresh Data"):
    st.rerun()
