FROM mcr.microsoft.com/devcontainers/python:{{cookiecutter.python_version}}-bullseye

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends postgresql-client \
    && apt-get update && apt-get install -y xdg-utils \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

WORKDIR /demo-code

COPY requirements.txt .
RUN python -m pip install -r requirements.txt

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

COPY . .
CMD bash -c ". entrypoint.sh"
