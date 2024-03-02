#!/bin/bash
set -e
python3 -m pip install --upgrade pip
{% if cookiecutter.project_backend in ("flask", "fastapi") %}
python3 -m pip install -e .
{% endif %}
{% if cookiecutter.project_backend == "flask" %}
{% if "postgres" in cookiecutter.db_resource  or "mysql" in cookiecutter.db_resource%}
python3 -m flask --app flaskapp db upgrade --directory flaskapp/migrations
{% endif %}
python3 -m flask --app flaskapp seed --filename="seed_data.json"
python3 -m gunicorn "flaskapp:create_app()"
{% endif %}
{% if cookiecutter.project_backend == "fastapi" %}
python3 fastapi_app/seed_data.py
python3 -m gunicorn fastapi_app:app
{% endif %}
{% if cookiecutter.project_backend == "django" %}
echo "${0}: running migrations."
python3 manage.py migrate
python3 manage.py loaddata seed_data.json
python3 manage.py collectstatic --no-input
python3 -m gunicorn project.wsgi:application
{% endif %}
