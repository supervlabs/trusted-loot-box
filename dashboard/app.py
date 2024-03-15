import plotly.express as px
import streamlit as st

from data_handler import get_rewards_data

st.set_page_config(
    page_title="Trusted Loot Box",
    page_icon="🎲",
    layout="wide",
    initial_sidebar_state="auto",
)

df = get_rewards_data(1000)

# Show Metrics
df_count = df.iloc[:, 1:].sum()
n_trial = df_count.sum()
n_reward_grades = len(df_count)
names = df_count.index.tolist()
names = ["Total Trials"] + [n.capitalize() for n in names]
values = [n_trial] + df_count.tolist()

n_metrics = n_reward_grades + 1
st.markdown("**Metrics:**")
for i, col in enumerate(st.columns([1] * n_metrics + [6])):
    if i == n_metrics:
        continue
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
    fig = px.imshow(
        df_heatmap,
        x=df.index + 1,
        title="Rewards at Each Trial",
        labels={"x": "# Trials", "y": "Rewards"},
        color_continuous_scale=["white", "blue"],
    ).update_layout(coloraxis_showscale=False)
    st.plotly_chart(fig)
