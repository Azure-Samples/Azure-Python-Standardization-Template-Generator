param name string
param location string = resourceGroup().location
param tags object = {}

param applicationInsightsName string
param containerAppsEnvironmentName string
param containerRegistryName string
param exists bool
param identityName string
param serviceName string = 'web'
{% if cookiecutter.db_resource in ("postgres-flexible", "cosmos-postgres") %}
param dbserverDomainName string
param dbserverDatabaseName string
param dbserverUser string
@secure()
param dbserverPassword string
{% endif %}
{% if cookiecutter.project_backend in ("django", "flask") %}
@secure()
param secretKey string
{% endif %}
param postgresServiceId string

resource webIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

{% if cookiecutter.project_host == "aca" %}
module app 'core/host/container-app-upsert.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    identityName: webIdentity.name
    exists: exists
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    env: [
      {% if cookiecutter.db_resource in ("postgres-flexible", "cosmos-postgres") %}
      {
        name: 'POSTGRES_HOST'
        value: dbserverDomainName
      }
      {
        name: 'POSTGRES_USERNAME'
        value: dbserverUser
      }
      {
        name: 'POSTGRES_DATABASE'
        value: dbserverDatabaseName
      }
      {
        name: 'POSTGRES_PASSWORD'
        secretRef: 'dbserver-password'
      }
      {% endif %}
      {
        name: 'RUNNING_IN_PRODUCTION'
        value: 'true'
      } 
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: applicationInsights.properties.ConnectionString
      }
      {% if cookiecutter.project_backend in ("django", "flask") %}
      {
        name: 'SECRET_KEY'
        secretRef: 'secret-key'
      }
      {% endif %}
      ]
    secrets: [
        {% if cookiecutter.db_resource in ("postgres-flexible", "cosmos-postgres") %}
        {
          name: 'dbserver-password'
          value: dbserverPassword
        }
        {% endif %}
        {% if cookiecutter.project_backend in ("django", "flask") %}
        {
          name: 'secret-key'
          value: secretKey
        }
        {% endif %}
      ]
    {% if cookiecutter.db_resource == "postgres-service" %}
    postgresServiceId: postgresServiceId
    {% endif %}
    targetPort: {{cookiecutter.web_port}} 
  }
}
{% endif %}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = webIdentity.properties.principalId
output SERVICE_WEB_NAME string = app.outputs.name
output SERVICE_WEB_URI string = app.outputs.uri
output SERVICE_WEB_IMAGE_NAME string = app.outputs.imageName
