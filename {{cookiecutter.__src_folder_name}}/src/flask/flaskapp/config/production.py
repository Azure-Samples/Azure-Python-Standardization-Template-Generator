import os
{% if 'mongo' in cookiecutter.db_resource %}
import pymongo
{% endif %}

{% if 'mongo' in cookiecutter.db_resource %}
# Create a mongoDB Connection
client = pymongo.MongoClient("DATABASE_CONNECTION_STRING")
{% endif %}
DEBUG = False


if "WEBSITE_HOSTNAME" in os.environ:
    ALLOWED_HOSTS = [os.environ["WEBSITE_HOSTNAME"]]
else:
    ALLOWED_HOSTS = []

{% if cookiecutter.db_resource == "postgres-addon" %}
# The PostgreSQL service binding will always set env variables with these names.
{% endif %}

{% if 'postgres' in cookiecutter.db_resource %}
dbuser = os.environ["POSTGRES_USERNAME"]
dbpass = os.environ["POSTGRES_PASSWORD"]
dbhost = os.environ["POSTGRES_HOST"]
dbname = os.environ["POSTGRES_DATABASE"]
dbport = os.environ.get("POSTGRES_PORT", 5432)
{% if cookiecutter.db_resource == "postgres-addon" %}
# The PostgreSQL service binding will typically set POSTGRES_SSL to disable.
{% endif %}
sslmode = os.environ.get("POSTGRES_SSL")
DATABASE_URI = f"postgresql+psycopg2://{dbuser}:{dbpass}@{dbhost}:{dbport}/{dbname}"
if sslmode:
    DATABASE_URI = f"{DATABASE_URI}?sslmode={sslmode}"
{% endif %}

{% if 'mongo' in cookiecutter.db_resource %}
DATABASE_URI  = os.environ["AZURE_COSMOS_CONNECTION_STRING"]
{% endif %}
