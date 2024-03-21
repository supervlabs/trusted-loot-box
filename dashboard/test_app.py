from streamlit.testing.v1 import AppTest


def test_update_dataframe():
    at = AppTest.from_file("app.py").run()

    df = at.session_state["df"]
    lasted_datetime = df.iloc[-1]["created_at"].isoformat() + "Z"
    assert at.session_state["last_updated"] == lasted_datetime

    # at.run()
    # df = at.session_state["df"]
    # assert lasted_datetime != at.session_state["last_updated"]
    # assert len(df) == 2000
