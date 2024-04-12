# Dashboard of Trusted Loot Box

## Description

This is a dashboard that provides a visual representation of Loot Box data. It is designed to make reward data sets understandable. Users can see the dashboard to understand what happened in the past and what is happening now.

## Installation

This dashboard is built using [Streamlit](https://streamlit.io/).
Python 3.12 is required to run the dashboard and it is recommended to use a virtual environment such as `venv` or `virtualenv`.

To run the dashboard locally, you need to install Streamlit and other dependencies. You can do so by running the following command:


```bash
cd dashboard  # Change to the directory `dashboard`
pip install -r requirements.txt
```

`API_URL` is the URL of the API server. You can set it as an environment variable or save it in a `.env` file in the root directory of the dashboard.


Run the dashboard using the following command:

```bash
# Run the dashboard in the directory `dashboard`
streamlit run app.py
```

## Environment Variables

The following environment variables are used in the dashboard:

- `API_URL`: The URL of the API server. This is used to fetch data from the API server.
- `TTL`: The time-to-live of the cache in seconds. This is used to cache the data fetched from the API server.

You can set these environment variables in a `.env` file in the root directory of the dashboard.
Or you can set them in the terminal as environment variables before running the dashboard.
The evironment variables override the values in the `.env` file.
You can see the details in Python dotenv [documentation](https://pypi.org/project/python-dotenv/).
This repository has a [`.env.example`](.env.example) file that you can use as a template.


## Distributed Dashboard

The dashboard is also available online. You can access it [here](https://trusted-loot-box.onrender.com/).
