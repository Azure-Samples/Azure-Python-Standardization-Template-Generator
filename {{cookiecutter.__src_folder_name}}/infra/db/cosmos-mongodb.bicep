param name string
param location string = resourceGroup().location
param tags object = {}
param prefix string
param dbserverDatabaseName string
param sqlRoleAssignmentPrincipalId string
param keyvaultName string

module databaseAccount 'br/public:avm/res/document-db/database-account:0.5.6' = {
  name: name
  params: {
    name: '${take(prefix, 36)}-mongodb' // Max 44 characters
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
  }
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: name
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
}

output id string = databaseAccount.outputs.resourceId
output endpoint string  = databaseAccount.outputs.endpoint
