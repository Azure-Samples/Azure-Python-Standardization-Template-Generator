{# This is the appservice version of `web.bicep` selected by post_gen_project.py #}
param name string
param location string = resourceGroup().location
param tags object = {}
param pythonVersion string
param appCommandLine string
param keyVaultName string
param applicationInsightsName string
{% if "postgres" in cookiecutter.db_resource %}
param dbserverDomainName string
param dbserverUser string
param dbserverDatabaseName string
{% endif %}
param virtualNetworkSubnetId string = ''

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

module appServicePlan 'core/host/appserviceplan.bicep' = {
  name: 'serviceplan'
  params: {
    name: '${name}-serviceplan'
    location: location
    tags: tags
    sku: {
      name: 'B1'
    }
    reserved: true
  }
}

module web 'core/host/appservice.bicep' = {
  name: 'appservice'
  params: {
    name: '${name}-web'
    location: location
    tags: union(tags, {'azd-service-name': 'web'})
    appCommandLine: appCommandLine
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVaultName
    runtimeName: 'python'
    runtimeVersion: pythonVersion
    scmDoBuildDuringDeployment: true
    ftpsState: 'Disabled'
    managedIdentity: true
    appSettings: {
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
      RUNNING_IN_PRODUCTION: 'true'
      {% if "postgres" in cookiecutter.db_resource %}
      POSTGRES_HOST: dbserverDomainName
      POSTGRES_USERNAME: dbserverUser
      POSTGRES_DATABASE: dbserverDatabaseName
      POSTGRES_PASSWORD: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=DBSERVERPASSWORD)'
      POSTGRES_SSL: 'require'
      {% endif %}
      {% if cookiecutter.project_backend in ("django", "flask") %}
      SECRET_KEY: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=SECRETKEY)'
      {% endif %}
      {% if 'mongodb' in cookiecutter.db_resource %}
      AZURE_COSMOS_CONNECTION_STRING: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=AZURE-COSMOS-CONNECTION-STRING)'
      {% endif %}
    }
    virtualNetworkSubnetId: virtualNetworkSubnetId
  }
}

// Give the app access to KeyVault
module webKeyVaultAccess './core/security/role.bicep' = {
  name: 'web-keyvault-access'
  params: {
    principalId: web.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  }
}

output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = web.outputs.identityPrincipalId

output uri string = web.outputs.uri
