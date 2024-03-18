from streamlit.testing.v1 import AppTest


def test_update_dataframe():
    at = AppTest.from_file("app.py").run()

    df = at.session_state["df"]
    lasted_datetime = df.iloc[-1]["datetime"].isoformat() + "Z"
    assert at.session_state["last_updated"] == lasted_datetime
    assert len(df) == 1000

    at.run()
    df = at.session_state["df"]
    assert lasted_datetime != at.session_state["last_updated"]
    assert len(df) == 2000
