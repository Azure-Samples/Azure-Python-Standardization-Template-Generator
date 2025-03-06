param containerAppsEnvironmentName string
param name string
param location string = resourceGroup().location
param tags object = {}
param prefix string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppsEnvironmentName
}

resource postgres 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: '${take(prefix, 29)}-pg' // max 32 characters
  location: location
  tags: tags
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      service: {
          type: 'postgres'
      }
    }
  }
}

output id string = postgres.id
