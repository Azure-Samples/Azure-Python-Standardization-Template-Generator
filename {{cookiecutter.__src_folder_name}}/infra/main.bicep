targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name which is used to generate a short unique hash for each resource')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

{% if cookiecutter.db_resource in ("postgres-flexible", "cosmos-postgres") %}
@secure()
@description('DBServer administrator password')
param dbserverPassword string
{% else %}
var dbserverPassword = guid(name, resourceGroup.name) // Only used by the linter
{% endif %}

{% if cookiecutter.project_backend in ("django", "flask") %}
@secure()
@description('Secret Key')
param secretKey string
{% endif %}

{% if cookiecutter.project_host == "aca" %}
param webAppExists bool = false
{% endif %}

@description('Id of the user or app to assign application roles')
param principalId string = ''

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var prefix = '${name}-${resourceToken}'
var tags = { 'azd-env-name': name }

var DATABASE_RESOURCE = '{{cookiecutter.db_resource}}'
var PROJECT_HOST = '{{cookiecutter.project_host}}'

var secrets = [
  {% if cookiecutter.db_resource in ("postgres-flexible", "cosmos-postgres") %}
  {
    name: 'DBSERVERPASSWORD'
    value: dbserverPassword
  }
  {% endif %}
  {% if cookiecutter.project_backend in ("django", "flask") %}
  {
    name: 'SECRETKEY'
    value: secretKey
  }
  {% endif %}
]

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
  tags: tags
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.8' = {
  name: 'virtualNetworkDeployment'
  scope: resourceGroup
  params: {
    // Required parameters
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    name: '${name}-vnet'
    location: location
    tags: tags
    subnets: [
      {
        addressPrefix: '10.0.0.0/24'
        name: 'keyvault'
        tags: tags
      }
      {
        addressPrefix: '10.0.2.0/23'
        name: 'web'
        tags: tags
        {% if cookiecutter.project_host == "appservice" %}
        delegations: [
          {
            name: 'msft-web-serverfarm-delegation'
            properties: {
              serviceName: 'Microsoft.Web/serverFarms'
            }
          }
        ]
        {% endif %}
        serviceEndpoints: [
          { 
            service: 'Microsoft.KeyVault'
          }
        ]
      }
      {
        addressPrefix: '10.0.4.0/23'
        name: 'db'
        tags: tags
      }
    ]
  }
}

module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.3.1' = {
  name: 'privateDnsZoneDeployment'
  scope: resourceGroup
  params: {
    name: 'relecloud.net'
    tags: tags
  }
}

// Store secrets in a keyvault
module keyVault 'br/public:avm/res/key-vault/vault:0.6.2' = {
  name: 'keyvault'
  scope: resourceGroup
  params: {
    name: '${take(replace(prefix, '-', ''), 17)}-vault'
    location: location
    tags: tags
    sku: 'standard'
    enableRbacAuthorization: true
    accessPolicies: [
      {
        objectId: principalId
        permissions: { secrets: ['get', 'list'] }
        tenantId: subscription().tenantId
      }
    ]
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      // ipRules: [
      //   { value: '<your IP>' }
      // ]
      virtualNetworkRules: [
        {
          id: virtualNetwork.outputs.subnetResourceIds[1]
        }
      ]
    }
    privateEndpoints: [
      {
        name: '${name}-keyvault-pe'
        subnetResourceId: virtualNetwork.outputs.subnetResourceIds[0]
        privateDnsZoneResourceIds: [privateDnsZone.outputs.resourceId]
      }
    ]
    diagnosticSettings: [
      {
        logCategoriesAndGroups: [
          {
            category: 'AuditEvent'
          }
        ]
        name: 'auditEventLogging'
        workspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceId
      }
    ]
    secrets: [
      for secret in secrets: {
        name: secret.name
        value: secret.value
        tags: tags
        attributes: {
          exp: 0
          nbf: 0
        }
      }
    ]
  }
}

module roleAssignment 'core/security/role.bicep' = {
  name: 'webRoleAssignment'
  scope: resourceGroup
  params: {
    principalId: web.outputs.SERVICE_WEB_IDENTITY_PRINCIPAL_ID
    roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
  }
}

module cosmosMongoDb 'db/cosmos-mongodb.bicep' = if(DATABASE_RESOURCE == 'cosmos-mongodb') {
  name: 'cosmosMongoDb'
  scope: resourceGroup
  params: {
    name: 'dbserver'
    location: location
    tags: tags
    prefix: prefix
    dbserverDatabaseName: 'relecloud'
    sqlRoleAssignmentPrincipalId: web.outputs.SERVICE_WEB_IDENTITY_PRINCIPAL_ID
    keyvaultName: keyVault.outputs.name
    privateDNSZoneResourceId: privateDnsZone.outputs.resourceId
    subnetResourceId: virtualNetwork.outputs.subnetResourceIds[2]
  }
}

module cosmosPostgres 'db/cosmos-postgres.bicep' = if(DATABASE_RESOURCE == 'cosmos-postgres') {
  name: 'cosmosPostgres'
  scope: resourceGroup
  params: {
    name: 'dbserver'
    location: location
    tags: tags
    prefix: prefix
    dbserverDatabaseName: 'relecloud'
    dbserverPassword: dbserverPassword
  }
}

module postgresAddon 'db/postgres-addon.bicep' = if(DATABASE_RESOURCE == 'postgres-addon' && PROJECT_HOST == 'aca') {
  name: 'postgresAddon'
  scope: resourceGroup
  params: {
    name: 'dbserver'
    location: location
    tags: tags
    prefix: prefix
    containerAppsEnvironmentName: containerApps.outputs.environmentName
  }
}

module postgresFlexible 'db/postgres-flexible.bicep' = if(DATABASE_RESOURCE == 'postgres-flexible') {
  name: 'postgresFlexible'
  scope: resourceGroup
  params: {
    name: 'dbserver'
    location: location
    tags: tags
    prefix: prefix
    dbserverDatabaseName: 'relecloud'
    dbserverPassword: dbserverPassword
  }
}

// Monitor application with Azure Monitor
module monitoring 'core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    applicationInsightsDashboardName: '${prefix}-appinsights-dashboard'
    applicationInsightsName: '${prefix}-appinsights'
    logAnalyticsName: '${take(prefix, 50)}-loganalytics' // Max 63 chars
  }
}

// Container apps host (including container registry)
module containerApps 'core/host/container-apps.bicep' = if (PROJECT_HOST == 'aca') {
  name: 'container-apps'
  scope: resourceGroup
  params: {
    name: 'app'
    location: location
    containerAppsEnvironmentName: '${prefix}-containerapps-env'
    containerRegistryName: '${replace(prefix, '-', '')}registry'
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceId
    virtualNetworkSubnetId: virtualNetwork.outputs.subnetResourceIds[1]
  }
}

// Web frontend
module web 'web.bicep' = {
  name: 'web'
  scope: resourceGroup
  params: {
    {% if cookiecutter.project_host  == "aca" %}
    {% set host_type = "ca" %}
    {% endif %}
    {% if cookiecutter.project_host  == "appservice" %}
    {% set host_type = "appsvc" %}
    {% endif %}
    name: replace('${take(prefix,19)}-{{host_type}}', '--', '-')
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    keyVaultName: keyVault.outputs.name

    {% if cookiecutter.project_host == "appservice" %}
    appCommandLine: 'entrypoint.sh'
    pythonVersion: '{{cookiecutter.python_version}}'
    virtualNetworkSubnetId: virtualNetwork.outputs.subnetResourceIds[1]
    {% endif %}

    {% if cookiecutter.project_host == "aca" %}
    identityName: '${prefix}-id-web'
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    exists: webAppExists
    {% endif %}

    {% if cookiecutter.db_resource  == "postgres-flexible" %}
    dbserverDomainName: postgresFlexible.outputs.dbserverDomainName
    dbserverUser: postgresFlexible.outputs.dbserverUser
    dbserverDatabaseName: postgresFlexible.outputs.dbserverDatabaseName
    {% endif %}

    {% if cookiecutter.db_resource  == "cosmos-postgres" %}
    dbserverDomainName: cosmosPostgres.outputs.dbserverDomainName
    dbserverUser: cosmosPostgres.outputs.dbserverUser
    dbserverDatabaseName: cosmosPostgres.outputs.dbserverDatabaseName
    {% endif %}

    {% if cookiecutter.project_host == "aca" and cookiecutter.db_resource in ("postgres-flexible", "cosmos-postgres") %}
    dbserverPassword: dbserverPassword
    {% endif %}

    {% if cookiecutter.db_resource == "postgres-addon" %}
    postgresServiceId: postgresAddon.outputs.id
    {% endif %}
  }
}

output AZURE_LOCATION string = location
{% if cookiecutter.project_host == "aca" %}
output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.registryName
output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = web.outputs.SERVICE_WEB_IDENTITY_PRINCIPAL_ID
output SERVICE_WEB_NAME string = web.outputs.SERVICE_WEB_NAME
output SERVICE_WEB_URI string = web.outputs.SERVICE_WEB_URI
output SERVICE_WEB_IMAGE_NAME string = web.outputs.SERVICE_WEB_IMAGE_NAME
{% endif %}
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.uri
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output APPLICATIONINSIGHTS_NAME string = monitoring.outputs.applicationInsightsName

output BACKEND_URI string = web.outputs.uri
