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

## Deployment

There are three versions of the dashboard available:

### Random Hack

[randomhack](https://github.com/supervlabs/trusted-loot-box/tree/randomhack) branch is the live branch for aptos random hackathon. It is deployed on render.com. You can access it [here](https://trusted-loot-box.onrender.com/).

### Sidekick Draw - Dev

[deploy-dev](https://github.com/supervlabs/trusted-loot-box/tree/deploy-dev) branch is the development branch for Sidekick Draw. It is deployed on render.com. You can access it [here](https://sidekickdraw-dev.onrender.com/).

Dev version of Sidekick Draw event is available [here](https://devci.web.vir.supervlabs.net/sidekick-draw-event)


### Sidekick Draw - Prod
[deploy-live](https://github.com/supervlabs/trusted-loot-box/tree/deploy-live) branch is the production branch for Sidekick Draw. It is deployed on render.com. You can access it [here](https://sidekickdraw.onrender.com/).

Sidekick Draw events are available [here](https://supervlabs.io/sidekick-draw-event)

## Distributed Dashboard for Aptos random hack

The dashboard is also available online. You can access it [here](https://trusted-loot-box.onrender.com/).
