import pandas as pd
import plotly.graph_objs as go  # type: ignore
import streamlit as st
from data_handler import GRADES, PROB_DICT, TTL, get_count, get_onehot_cumsum
from scipy.stats import beta  # type: ignore
from streamlit_autorefresh import st_autorefresh  # type: ignore

# Set default mode to copy-on-write to avoid SettingWithCopyWarning in Pandas
# https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy
pd.options.mode.copy_on_write = True

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
colors_dict = dict(zip(GRADES, colors))


st.title("Sidekick Draw - Dashboard")

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


df_onehot_cumsum = get_onehot_cumsum(n_trial)
df_onehot_cumsum.columns = df_onehot_cumsum.columns.str.capitalize()


def show_prob_with_CI(
    alpha: float, df_onehot_cumsum: pd.DataFrame, grade: str, y_range_value: float
):
    assert grade in GRADES
    prob_name = grade + "_prob"
    prob = PROB_DICT[grade]

    df_onehot_cumsum[prob_name] = (
        df_onehot_cumsum[grade] / df_onehot_cumsum["Total_minted"] * 100
    )

    df_onehot_cumsum["Lower_bound"] = (
        beta.ppf(
            alpha / 2,
            df_onehot_cumsum[grade],
            df_onehot_cumsum["Total_minted"] - df_onehot_cumsum[grade] + 1,
        )
        * 100
    )
    df_onehot_cumsum["Upper_bound"] = (
        beta.ppf(
            1 - alpha / 2,
            df_onehot_cumsum[grade] + 1,
            df_onehot_cumsum["Total_minted"] - df_onehot_cumsum[grade],
        )
        * 100
    )

    fig = go.Figure(
        [
            go.Scatter(
                name="Probability",
                x=df_onehot_cumsum["Skey"],
                y=df_onehot_cumsum[prob_name],
                mode="lines",
                line=dict(color=colors_dict[grade]),
            ),
            go.Scatter(
                name="Upper Bound",
                x=df_onehot_cumsum["Skey"],
                y=df_onehot_cumsum["Upper_bound"],
                mode="lines",
                marker=dict(color="#444"),
                line=dict(width=0),
                showlegend=False,
            ),
            go.Scatter(
                name="Lower Bound",
                x=df_onehot_cumsum["Skey"],
                y=df_onehot_cumsum["Lower_bound"],
                mode="lines",
                marker=dict(color="#444"),
                line=dict(width=0),
                fillcolor="rgba(68, 68, 68, 0.3)",
                fill="tonexty",
                showlegend=False,
            ),
        ]
    )
    fig.update_layout(
        yaxis_title=grade + " Probability (%)",
        xaxis_title="Date (UTC)",
        title=grade + " Probability with 99% Confidence Interval",
        hovermode="x",
        yaxis=dict(
            range=[prob * 100 - y_range_value, prob * 100 + y_range_value],
            tickformat=".2f",
            ticksuffix="%",
        ),
        showlegend=False,
    )
    fig.add_hline(
        y=prob * 100,
        line_dash="dot",
        line_color="red",
        annotation_text=f"    Designed Prob(%) baseline: {prob * 100}%",
        annotation_position="top left",
    )
    st.plotly_chart(fig, use_container_width=True, height=600)


st.markdown("##### Probability Time Series")
alpha = 0.01

show_prob_with_CI(alpha, df_onehot_cumsum, "Legendary", 0.1)
show_prob_with_CI(alpha, df_onehot_cumsum, "Epic", 0.4)
show_prob_with_CI(alpha, df_onehot_cumsum, "Rare", 0.8)
show_prob_with_CI(alpha, df_onehot_cumsum, "Uncommon", 1.4)
show_prob_with_CI(alpha, df_onehot_cumsum, "Common", 2)


# Auto refresh the page
refresh_interval_seconds = TTL
refresh_maintaining_minutes = 30
refresh_limit = int(refresh_maintaining_minutes * 60 / refresh_interval_seconds)
st_autorefresh(
    interval=refresh_interval_seconds * 1000,
    limit=refresh_limit,
    key="trusted_loot_box",
)
