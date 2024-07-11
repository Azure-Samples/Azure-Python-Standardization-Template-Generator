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
        permissions: { secrets: [ 'get', 'list' ] }
        tenantId: subscription().tenantId
      }
    ]
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
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
    secrets: [for secret in secrets: {
        name: secret.name
        value: secret.value
        tags: tags
        attributes : {
          exp: 0
          nbf: 0
        }
    }]
    
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

module db 'db.bicep' = {
  name: 'db'
  scope: resourceGroup
  params: {
    name: 'dbserver'
    location: location
    tags: tags
    prefix: prefix
    {% if "mongodb" in cookiecutter.db_resource %}
    keyVaultName: keyVault.outputs.name
    {% endif %}
    {% if cookiecutter.db_resource != "postgres-addon" %}
    dbserverDatabaseName: 'relecloud'
    {% endif %}
    {% if cookiecutter.db_resource in ("postgres-flexible", "cosmos-postgres")%}
    dbserverPassword: dbserverPassword
    {% endif %}
    {% if cookiecutter.db_resource == "postgres-addon" %}
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    {% endif %}
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

{% if cookiecutter.project_host == "aca" %}
// Container apps host (including container registry)
module containerApps 'core/host/container-apps.bicep' = {
  name: 'container-apps'
  scope: resourceGroup
  params: {
    name: 'app'
    location: location
    containerAppsEnvironmentName: '${prefix}-containerapps-env'
    containerRegistryName: '${replace(prefix, '-', '')}registry'
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
  }
}
{% endif %}

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
    {% endif %}
    {% if cookiecutter.project_host == "aca" %}
    identityName: '${prefix}-id-web'
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    exists: webAppExists
    {% endif %}
    {% if cookiecutter.db_resource in ("postgres-flexible", "cosmos-postgres") %}
    dbserverDomainName: db.outputs.dbserverDomainName
    dbserverUser: db.outputs.dbserverUser
    dbserverDatabaseName: db.outputs.dbserverDatabaseName
    {% if cookiecutter.project_host == "aca" %}
    dbserverPassword: dbserverPassword
    {% endif %}
    {% endif %}
    {% if cookiecutter.db_resource == "postgres-addon" %}
    postgresServiceId: db.outputs.dbserverID
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
