param name string
param location string = resourceGroup().location
param tags object = {}
param prefix string
param dbserverDatabaseName string
param sqlRoleAssignmentPrincipalId string
param keyvaultName string
param privateDNSZoneResourceId string
param subnetResourceId string

var mongoDbName = '${take(prefix, 36)}-mongodb'

module databaseAccount 'br/public:avm/res/document-db/database-account:0.5.6' = {
  name: name
  params: {
    name: mongoDbName // Max 44 characters
    location: location
    tags: tags

    managedIdentities: {
      systemAssigned: true
    }
    defaultConsistencyLevel: 'Session'
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    disableKeyBasedMetadataWriteAccess: true // See PsRule AZR-000095
    sqlRoleAssignmentsPrincipalIds: [sqlRoleAssignmentPrincipalId]
    mongodbDatabases: [
      {
        name: dbserverDatabaseName
      }
    ]
    networkRestrictions: {
      publicNetworkAccess: 'Disabled'
      ipRules: []
      virtualNetworkRules: [
        {subnetResourceId: subnetResourceId}
      ]
    }
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          privateDNSZoneResourceId
        ]
        service: 'MongoDB'
        subnetResourceId: subnetResourceId
        tags: tags
      }
    ]
  }
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: mongoDbName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyvaultName
}

resource cosmosConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'AZURE-COSMOS-CONNECTION-STRING'
  properties: {
    value: cosmos.listConnectionStrings().connectionStrings[0].connectionString
  }
  dependsOn: [databaseAccount]
}

output id string = databaseAccount.outputs.resourceId
output endpoint string  = databaseAccount.outputs.endpoint
