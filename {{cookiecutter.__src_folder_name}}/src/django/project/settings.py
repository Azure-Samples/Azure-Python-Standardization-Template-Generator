"""
Django settings for project project.

Generated by 'django-admin startproject' using Django 3.1.7.

For more information on this file, see
https://docs.djangoproject.com/en/3.1/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/3.1/ref/settings/
"""

import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Determine whether we're in production, as this will affect many settings.
prod = bool(os.environ.get("RUNNING_IN_PRODUCTION", False))

if not prod:  # Running in a Test/Development environment
    DEBUG = True # SECURITY WARNING: don't run with debug turned on in production!
    DEFAULT_SECRET = "insecure-secret-key"
    ALLOWED_HOSTS = []
    CSRF_TRUSTED_ORIGINS = [
        "http://localhost:8000",
    ]
    if os.environ.get("CODESPACE_NAME"):
        CSRF_TRUSTED_ORIGINS.append(
            f"https://{os.environ.get('CODESPACE_NAME')}-{{cookiecutter.web_port}}.{os.environ.get('GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN')}"
        )
else:  # Running in a Production environment
    DEBUG = False
    DEFAULT_SECRET = None
    ALLOWED_HOSTS = [
        {% if cookiecutter.project_host == "aca" %}os.environ["CONTAINER_APP_NAME"] + "." + os.environ["CONTAINER_APP_ENV_DNS_SUFFIX"],{% endif %}
        {% if cookiecutter.project_host == "appservice" %}os.environ["WEBSITE_HOSTNAME"],{% endif %}
    ]
    CSRF_TRUSTED_ORIGINS = [
        {% if cookiecutter.project_host == "aca" %}"https://" + os.environ["CONTAINER_APP_NAME"] + "." + os.environ["CONTAINER_APP_ENV_DNS_SUFFIX"],{% endif %}
        {% if cookiecutter.project_host == "appservice" %}"https://" + os.environ['WEBSITE_HOSTNAME'],{% endif %}
    ]

SECRET_KEY = os.environ.get("SECRET_KEY", DEFAULT_SECRET)

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "crispy_forms",
    "crispy_bootstrap4",
    "relecloud.apps.RelecloudConfig",
]

CRISPY_TEMPLATE_PACK = "bootstrap4"

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "project.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "project.wsgi.application"


# https://docs.djangoproject.com/en/3.1/ref/settings/#databases

db_options = {}
{% if cookiecutter.db_resource == "postgres-addon" %}
# The PostgreSQL service binding will typically set POSTGRES_SSL to disable.
{% endif %}
if ssl_mode := os.environ.get("POSTGRES_SSL"):
    db_options = {"sslmode": ssl_mode}

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        {% if cookiecutter.db_resource == "postgres-addon" %}
        # The PostgreSQL service binding will always set env variables with these names.
        {% endif %}
        "NAME": os.environ.get("POSTGRES_DATABASE"),
        "USER": os.environ.get("POSTGRES_USERNAME"),
        "PASSWORD": os.environ.get("POSTGRES_PASSWORD"),
        "HOST": os.environ.get("POSTGRES_HOST"),
        "PORT": os.environ.get("POSTGRES_PORT", 5432),
        "OPTIONS": db_options,
    }
}

DEFAULT_AUTO_FIELD = "django.db.models.AutoField"

# Password validation
# https://docs.djangoproject.com/en/3.1/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]


# Internationalization
# https://docs.djangoproject.com/en/3.1/topics/i18n/

LANGUAGE_CODE = "en-us"

TIME_ZONE = "UTC"

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/3.1/howto/static-files/

STATIC_URL = "/static/"
STATICFILES_DIRS = [BASE_DIR / "static"]
STATIC_ROOT = BASE_DIR / "staticfiles"

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "DEBUG",
    },
}

DJANGO_LOG_LEVEL = DEBUG
DEBUG_PROPAGATE_EXCEPTIONS = DEBUG # Enables VS Code debugger to break on raised exceptions
