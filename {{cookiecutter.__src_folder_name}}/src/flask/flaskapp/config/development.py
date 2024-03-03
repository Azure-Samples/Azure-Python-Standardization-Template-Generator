import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

DEBUG = True

{% if 'postgres' in cookiecutter.db_resource %}
dbuser = os.environ["POSTGRES_USERNAME"]
dbpass = os.environ["POSTGRES_PASSWORD"]
dbhost = os.environ["POSTGRES_HOST"]
dbname = os.environ["POSTGRES_DATABASE"]
dbport = os.environ.get("POSTGRES_PORT", 5432)
DATABASE_URI = f"postgresql+psycopg2://{dbuser}:{dbpass}@{dbhost}:{dbport}/{dbname}"
{% endif %}

{% if 'mysql' in cookiecutter.db_resource %}
dbuser = os.environ["MYSQL_USER"]
dbpass = os.environ["MYSQL_PASS"]
dbhost = os.environ["MYSQL_HOST"]
dbname = os.environ["MYSQL_DATABASE"]
dbport = os.environ.get("MYSQL_PORT", 3306)
DATABASE_URI = f"mysql+mysqlconnector://{dbuser}:{dbpass}@{dbhost}:{dbport}/{dbname}"
{% endif %}

{% if 'mongo' in cookiecutter.db_resource %}
dbuser = os.environ["MONGODB_USERNAME"]
dbpass = os.environ["MONGODB_PASSWORD"]
dbhost = os.environ["MONGODB_HOST"]
dbname = os.environ["MONGODB_DATABASE"]
DATABASE_URI  = f"mongodb://{dbuser}:{dbpass}@{dbhost}/{dbname}?authSource=admin"
{% endif %}
TIME_ZONE = "UTC"
