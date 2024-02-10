{% if "postgres" in cookiecutter.db_resource %}
{% set pg_version = 15 %}
{% endif %}

param name string
param location string = resourceGroup().location
param tags object = {}
param prefix string
{# Define the dbserverUser. in cosmos-postgres it is 'citus' and in postgres aca add-on it is predefined #}
{% if cookiecutter.db_resource == "cosmos-postgres" %}
// value is read-only in cosmos
var dbserverUser = 'citus'
{% elif cookiecutter.db_resource in ("postgres-flexible", "mysql-flexible") %}
var dbserverUser = 'admin${uniqueString(resourceGroup().id)}'
{% endif %}
{# Create the dbserverPassword this is only required for postgres instances #}
{% if cookiecutter.db_resource in ("postgres-flexible", "mysql-flexible", "cosmos-postgres") %}
@secure()
param dbserverPassword string
{% endif %}
{% if cookiecutter.db_resource != "postgres-addon" %}
param dbserverDatabaseName string
{% endif %}
{% if "mongodb" in cookiecutter.db_resource %}
param keyVaultName string
{% endif %}
{% if cookiecutter.db_resource == "postgres-addon" %}
param containerAppsEnvironmentName string
{% endif %}

{# Postgres ACA Add-on #}
{% if cookiecutter.db_resource == "postgres-addon" %}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppsEnvironmentName
}

module dbserver 'core/database/postgresql/aca-service.bicep' = {
  name: name
  params: {
    name: '${take(prefix, 29)}-pg' // max 32 characters
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.id
  }
}
{% endif %}
{# Postgres Flexible Server #}
{% if cookiecutter.db_resource == "postgres-flexible" %}
module dbserver 'core/database/postgresql/flexibleserver.bicep' = {
  name: name
  params: {
    name: '${prefix}-postgresql'
    location: location
    tags: tags
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storage: {
      storageSizeGB: 32
    }
    version: '{{pg_version}}'
    administratorLogin: dbserverUser
    administratorLoginPassword: dbserverPassword
    databaseNames: [dbserverDatabaseName]
    allowAzureIPsFirewall: true
  }
}
{% endif %}
{# MySQL Flexible Server #}
{% if cookiecutter.db_resource == "mysql-flexible" %}
module dbserver 'core/database/mysql/flexibleserver.bicep' = {
  name: name
  params: {
    name: '${prefix}-mysql'
    location: location
    tags: tags
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storage: {
      storageSizeGB: 20
    }
    version: '8.0.21'
    administratorLogin: dbserverUser
    administratorLoginPassword: dbserverPassword
    databaseNames: [ dbserverDatabaseName ]
    allowAzureIPsFirewall: true
  }
}
{% endif %}
{# Cosmos PostgreSQL#}
{% if cookiecutter.db_resource == "cosmos-postgres" %}
module dbserver 'core/database/cosmos/cosmos-pg-adapter.bicep' = {
  name: name
  params: {
    name: '${prefix}-postgresql'
    location: location
    tags: tags
    postgresqlVersion: '{{pg_version}}'
    administratorLogin: dbserverUser
    administratorLoginPassword: dbserverPassword
    databaseName: dbserverDatabaseName
    allowAzureIPsFirewall: true
    coordinatorServerEdition: 'BurstableMemoryOptimized'
    coordinatorStorageQuotainMb: 131072
    coordinatorVCores: 1
    nodeCount: 0
    nodeVCores: 4
  }
}
{% endif %}
{# Cosmos MongoDB#}
{% if cookiecutter.db_resource == "cosmos-mongodb" %}
module dbserver 'core/database/cosmos/mongo/cosmos-mongo-db.bicep' = {
  name: name
  params: {
    accountName: '${prefix}-mongodb'
    location: location
    databaseName: dbserverDatabaseName
    tags: tags
    keyVaultName: keyVaultName
  }
}
{% endif %}

{% if cookiecutter.db_resource != "postgres-addon" %}
output dbserverDatabaseName string = dbserverDatabaseName
{% if "postgres" in cookiecutter.db_resource or "mysql" in  cookiecutter.db_resource %}
output dbserverUser string = dbserverUser
{% endif %}
{% endif %}
{% if cookiecutter.db_resource == "postgres-addon" %}
output dbserverID string = dbserver.outputs.id
{% endif %}
{% if cookiecutter.db_resource in ("postgres-flexible", "mysql-flexible", "cosmos-postgres") %}
output dbserverDomainName string = dbserver.outputs.domainName
{% endif %}
