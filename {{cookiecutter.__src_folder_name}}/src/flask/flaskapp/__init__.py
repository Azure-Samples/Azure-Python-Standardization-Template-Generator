import os

import click
from azure.monitor.opentelemetry import configure_azure_monitor
{% if 'mongodb' in cookiecutter.db_resource %}
import mongoengine as engine
{% endif %}
from flask import Flask
{% if 'postgres' in cookiecutter.db_resource %}
from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm import DeclarativeBase
{% endif %}


{% if 'postgres' in cookiecutter.db_resource %}
class BaseModel(DeclarativeBase):
    pass


db = SQLAlchemy(model_class=BaseModel)
migrate = Migrate()
{% endif %}

def create_app(test_config=None):
    # create and configure the app
    if os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING"):
        configure_azure_monitor()

    app = Flask(__name__, static_folder="../static", template_folder="../templates")

    # Load configuration for prod vs. dev
    is_prod_env = "RUNNING_IN_PRODUCTION" in os.environ
    if not is_prod_env:
        app.config.from_object("flaskapp.config.development")
    else:
        app.config.from_object("flaskapp.config.production")

    # Configure the database
    if test_config is not None:
        app.config.update(test_config)

    {% if 'postgres' in cookiecutter.db_resource %}
    app.config.update(SQLALCHEMY_DATABASE_URI=app.config.get("DATABASE_URI"), SQLALCHEMY_TRACK_MODIFICATIONS=False)

    db.init_app(app)
    migrate.init_app(app, db)
    {% endif %}
    {% if 'mongo' in cookiecutter.db_resource %}
    db = engine.connect(host=app.config.get("DATABASE_URI")) # noqa: F841
    {% endif %}

    from . import pages

    app.register_blueprint(pages.bp)

    @app.cli.command("seed")
    {% if 'mongodb' in cookiecutter.db_resource %}
    @click.option("--drop", is_flag=True, default=False)
    {% endif %}
    @click.option("--filename", default="seed_data.json")
    def seed_data(filename{% if 'mongodb' in cookiecutter.db_resource %}, drop{% endif %}):
        from . import seeder
        {% if 'postgres' in cookiecutter.db_resource %}
        seeder.seed_data(db, filename)
        {% endif %}
        {% if 'mongodb' in cookiecutter.db_resource %}
        seeder.seed_data(filename, drop=drop)
        {% endif %}
        click.echo("Database seeded!")

    return app
