{# standard library imports #}
{% if cookiecutter.project_backend == "fastapi" %}
import multiprocessing
import socket
import time
{% endif %}
{% if cookiecutter.project_backend == "flask" %}
import multiprocessing
import os
import pathlib
{% endif %}
{% if cookiecutter.project_backend == "django" %}
import os
{% endif %}
import sys

{# third-party library imports #}
import pytest
{% if cookiecutter.project_backend == "flask" %}
import ephemeral_port_reserve
from flask import Flask
{% endif %}
{% if 'mongodb' in cookiecutter.db_resource %}
import mongoengine as engine
{% endif %}
{% if cookiecutter.project_backend == "fastapi" %}
import ephemeral_port_reserve
import requests
import uvicorn
{% endif %}
{% if cookiecutter.project_backend == "django" %}
from django.core.management import call_command
{% endif %}

{# Local imports #}
{% if cookiecutter.project_backend == "fastapi" %}
from fastapi_app import seed_data
from fastapi_app.app import app

{% endif %}
{% if cookiecutter.project_backend == "flask" %}
from flaskapp import create_app, seeder
{% if 'postgres' in cookiecutter.db_resource %}
from flaskapp import db
{% endif %}
{% endif %}

{% if cookiecutter.project_backend in ("flask", "fastapi") %}
# Set start method to "fork" to avoid issues with pickling on OSes that default to "spawn"
if sys.platform != "win32":
    multiprocessing.set_start_method("fork")
{% endif %}

{% if cookiecutter.project_backend == "fastapi" %}
def wait_for_server_ready(
    url: str, timeout: float = 10.0, check_interval: float = 0.5
) -> bool:
    """Make requests to provided url until it responds without error."""
    conn_error = None
    for _ in range(int(timeout / check_interval)):
        try:
            requests.get(url)
        except requests.ConnectionError as exc:
            time.sleep(check_interval)
            conn_error = str(exc)
        else:
            return True
    raise RuntimeError(conn_error)


def run_server(port: int):
    uvicorn.run(app, port=port)
{% endif %}

{% if cookiecutter.project_backend == "flask" %}
def run_server(app: Flask, port: int):
    app.run(port=port, debug=False)


{% if 'postgres' in cookiecutter.db_resource %}
{% from 'conftest_flask_postgres.py' import app with context %}
{% endif %}
{% if 'mongodb' in cookiecutter.db_resource %}
{% from 'conftest_flask_mongodb.py' import app with context %}
{% endif %}
{{app()}}
{% endif %}

{% if cookiecutter.project_backend == "django" %}
@pytest.fixture(scope="function")
def django_db_setup(django_db_setup, django_db_blocker):
    """ Overrides the default django_db_setup fixture to load the seed data
    https://pytest-django.readthedocs.io/en/latest/database.html#populate-the-test-database-if-you-use-transactional-or-live-server
    """
    with django_db_blocker.unblock():
        call_command("loaddata", "src/seed_data.json")


@pytest.fixture(scope="session", autouse=True)
def mock_functions_env():
    os.environ["DJANGO_ALLOW_ASYNC_UNSAFE"] = "true"


@pytest.fixture(scope="session")
def live_server_url(live_server):
    """Returns the url of the live server"""
    return live_server.url
{% endif %}
{% if cookiecutter.project_backend == "fastapi" %}
@pytest.fixture(scope="session")
def live_server_url():
    """Returns the url of the live server"""
    seed_data.load_from_json()

    # Start the process
    hostname = ephemeral_port_reserve.LOCALHOST
    free_port = ephemeral_port_reserve.reserve()
    proc = multiprocessing.Process(target=run_server, args=(free_port,), daemon=True)
    proc.start()

    # Return the URL of the live server once it is ready
    url = f"http://{hostname}:{free_port}"
    wait_for_server_ready(url, timeout=10.0, check_interval=0.5)
    yield url

    # Clean up the process and database
    proc.kill()
    seed_data.drop_all()
{% endif %}
{% if cookiecutter.project_backend == "flask" %}


@pytest.fixture(scope="session")
def live_server_url(app_with_db):
    """Returns the url of the live server"""

    # Start the process
    hostname = ephemeral_port_reserve.LOCALHOST
    free_port = ephemeral_port_reserve.reserve(hostname)
    proc = multiprocessing.Process(
        target=run_server,
        args=(
            app_with_db,
            free_port,
        ),
        daemon=True,
    )
    proc.start()

    # Return the URL of the live server
    yield f"http://{hostname}:{free_port}"

    # Clean up the process
    proc.kill()
{% endif %}
