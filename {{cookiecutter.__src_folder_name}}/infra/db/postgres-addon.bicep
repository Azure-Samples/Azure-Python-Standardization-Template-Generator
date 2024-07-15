param containerAppsEnvironmentName string
param name string
param location string = resourceGroup().location
param tags object = {}
param prefix string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppsEnvironmentName
}

module dbserver '../core/database/postgresql/aca-service.bicep' =  {
  name: name
  params: {
    name: '${take(prefix, 29)}-pg' // max 32 characters
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.id
  }
}

output id string = dbserver.outputs.id
