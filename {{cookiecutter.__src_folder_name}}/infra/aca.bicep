{# This is the aca version of `web.bicep` selected by post_gen_project.py #}
param name string
param location string = resourceGroup().location
param tags object = {}

param applicationInsightsName string
param containerAppsEnvironmentName string
param containerRegistryName string
param exists bool
param identityName string
param serviceName string = 'web'
param keyVaultName string
{# The dbserver values do not exist in the postgres aca add-on #}
{% if cookiecutter.db_resource in ("postgres-flexible", "cosmos-postgres") %}
param dbserverDomainName string
param dbserverDatabaseName string
param dbserverUser string

@secure()
param dbserverPassword string
{% endif %}
{% if cookiecutter.db_resource == "postgres-addon" %}
param postgresServiceId string
{% endif %}

resource webIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Give the app access to KeyVault
module webKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'web-keyvault-access'
  params: {
    keyVaultName: keyVault.name
    principalId: webIdentity.properties.principalId
  }
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
      {% if 'postgres' in cookiecutter.db_resource %}
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
      {
        name: 'POSTGRES_SSL'
        value: 'require'
      }
      {% endif %}
      {% endif %}
      {
        name: 'RUNNING_IN_PRODUCTION'
        value: 'true'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: applicationInsights.properties.ConnectionString
      }
      {% if "mongodb" in cookiecutter.db_resource %}
      {
        name: 'AZURE_COSMOS_CONNECTION_STRING'
        secretRef: 'azure-cosmos-connection-string'
      }
      {% endif %}
      {% if cookiecutter.project_backend in ("django", "flask") %}
      {
        name: 'SECRET_KEY'
        secretRef: 'secret-key'
      }
      {% endif %}
      ]
    secrets: {
        {% if cookiecutter.db_resource in ("postgres-flexible", "cosmos-postgres") %}
          'dbserver-password': dbserverPassword
        {% endif %}
     }
    keyvaultIdentities: {
      {% if cookiecutter.project_backend in ("django", "flask") %}
      'secret-key': {
        keyVaultUrl: '${keyVault.properties.vaultUri}secrets/SECRETKEY'
        identity: webIdentity.id
      }
      {% endif %}
      {% if "mongodb" in cookiecutter.db_resource %}
        'azure-cosmos-connection-string': {
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/AZURE-COSMOS-CONNECTION-STRING'
          identity: webIdentity.id
        }
      {% endif %}
    }
    {% if cookiecutter.db_resource == "postgres-addon" %}
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

output uri string = app.outputs.uri
