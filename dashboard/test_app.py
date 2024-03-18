from streamlit.testing.v1 import AppTest


def test_dashboard():
    at = AppTest.from_file("app.py").run()

    df = at.session_state["df"]
    lasted_datetime = df.iloc[-1]["datetime"]
    assert at.session_state["last_updated"] == lasted_datetime
