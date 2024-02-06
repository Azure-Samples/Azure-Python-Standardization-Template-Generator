# Cookiecutter Relecloud

[![Github Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fkjaymiller%2Fcookiecutter-relecloud%2Fbadge%3Fref%3Dmain&style=flat-square)](https://actions-badge.atrox.dev/kjaymiller/cookiecutter-relecloud/goto?ref=main)

## Table of Contents
- [Table of Contents](#table-of-contents)
- [What is Cookiecutter-Relecloud?](#what-is-cookiecutter-relecloud)
- [Deployment Options](#deployment-options)
- [Deploying your cookiecutter template](#deploying-your-cookiecutter-template)
- [Getting Updates from this Template](#getting-updates-from-this-template)
- [Running your Deployment via DevContainer/Github Codespaces](#running-your-deployment-via-devcontainergithub-codespaces)
- [Deploy your template to Azure](#deploy-your-template-to-azure)

## What is Cookiecutter-Relecloud?

Cookiecutter is a command-line utility that creates projects from cookiecutters (project templates), e.g. creating a Python package project from a Python package project template.

Relecloud is a sample web app created by the Microsoft Python Cloud Advocacy team.

While most cookiecutter generated projects are designed to build with a particular stack, Cookiecutter-Relecloud allows you to create a relecloud project with your choice of web framework, database, and deployment options.

https://github.com/kjaymiller/cookiecutter-relecloud/assets/8632637/872a41ad-a48e-49ad-956e-370e302508d2

### Features

- Sync new updates to your project via [cruft](https://github.com/cruft/cruft)
- Deploy your project to Azure using [Azure Developer CLI](https://aka.ms/azd)

## Deployment Options

|Feature| Django | FastAPI | Flask |
|---|---|---|---|
|**Deployment**|-|-|-|
|Deploys via AZD|✅|✅|✅|
|Deploys via Terraform|❌|❌|❌|
|Deploys via ACA|✅|✅|✅|
|Deploys with Azure App Service|✅|✅|✅|
|**Databases**|-|-|-|
|Azure ACA Postgres Plugin|✅|✅|✅|
|Azure Cosmos DB (Postgres Adapter)|✅|✅|✅|
|Azure Cosmos DB (MongoDB)|❌|❌|✅|
|Azure Postgres Flexible Server|✅|✅|✅|
|Azure MySQL Flexible Server|❌|❌|✅|
|**Azure Add-ons**|-|-|-|
|Azure vNet|❌|❌|❌|
|Azure Secret KeyVault|✅|✅|✅|

|✅ (Developed)|🛠️ (In Development)|❌ (Currently Not Supported)|

To request support please create a [new discussion](https://github.com/kjaymiller/cookiecutter-relecloud/discussions/new?category=ideas).

### Deployed Project Examples

#### Django

----------

- [Django Postgres - Flexible Server Azure Container Apps](https://github.com/Azure-Samples/azure-django-postgres-flexible-aca)
- [Django Postgres - Flexible Server Azure App Service](https://github.com/Azure-Samples/azure-django-postgres-flexible-appservice)
- [Django CosmosDB Postgres Adapter Azure Container Apps](https://github.com/Azure-Samples/azure-django-cosmos-postgres-aca)
- [Django CosmosDB Postgres Adapter Azure App Service](https://github.com/Azure-Samples/azure-django-cosmos-postgres-appservice)
- [Django Azure Container Apps Postgres Addon  Azure Container Apps](https://github.com/Azure-Samples/azure-django-postgres-addon-aca)

#### FastAPI

----------

- [FastAPI Postgres - Flexible Server Azure Container Apps](https://github.com/Azure-Samples/azure-fastapi-postgres-flexible-aca)
- [FastAPI Postgres - Flexible Server Azure App Service](https://github.com/Azure-Samples/azure-fastapi-postgres-flexible-appservice)
- [FastAPI CosmosDB Postgres Adapter Azure Container Apps](https://github.com/Azure-Samples/azure-fastapi-cosmos-postgres-aca)
- [FastAPI CosmosDB Postgres Adapter Azure App Service](https://github.com/Azure-Samples/azure-fastapi-cosmos-postgres-appservice)
- [FastAPI Azure Container Apps Postgres Addon  Azure Container Apps](https://github.com/Azure-Samples/azure-fastapi-postgres-addon-aca)

#### Flask

----------

- [Flask Postgres - Flexible Server Azure Container Apps](https://github.com/Azure-Samples/azure-flask-postgres-flexible-aca)
- [Flask Postgres - Flexible Server Azure App Service](https://github.com/Azure-Samples/azure-flask-postgres-flexible-appservice)
- [Flask CosmosDB Postgres Adapter Azure Container Apps](https://github.com/Azure-Samples/azure-flask-cosmos-postgres-aca)
- [Flask CosmosDB Postgres Adapter Azure App Service](https://github.com/Azure-Samples/azure-flask-cosmos-postgres-appservice)
- [Flask Azure Container Apps Postgres Addon  Azure Container Apps](https://github.com/Azure-Samples/azure-flask-postgres-addon-aca)
- [Flask CosmosDB - MongoDB Adapter  Azure Container Apps](https://github.com/Azure-Samples/azure-flask-cosmos-mongodb-aca)
- [Flask CosmosDB - MongoDB Adapter  Azure App Service](https://github.com/Azure-Samples/azure-flask-cosmos-mongodb-appservice)
- [Flask MySQL - Flexible Server Azure App Service](https://github.com/john0isaac/azure-flask-mysql-flexible-appservice)
- [Flask MySQL - Flexible Server Azure Container Apps](https://github.com/john0isaac/azure-flask-mysql-flexible-aca)

## Deploying your cookiecutter template

1. Create a new folder
2. Create a virtual environment

```sh
python -m venv venv
source venv/bin/activate
```

2. Install necessary files

```sh
python -m pip install cruft packaging ruff 
```

3. Generate the project using this template

```sh
python -m cruft create https://github.com/kjaymiller/cookiecutter-relecloud
```

## Getting Updates from this Template

Cruft allows you to update your project with the latest changes from this template. To do so, run the following command:

```sh
cruft update
```

## Running your Deployment via DevContainer/Github Codespaces

This template is designed to work with DevContainers and GitHub Codespaces. You can deploy the Github Codespaces instance by clicking the green code button and creating a new codespace.

To deploy the dev container locally you can do so with a compatible code editor like Visual Studio Code.

## Deploy your template to Azure

These templates are configured to deploy to Microsoft Azure via the Azure Developer CLI. You can deploy your project immediately using `azd up`
