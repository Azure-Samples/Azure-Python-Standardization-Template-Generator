param name string
param location string = resourceGroup().location
param tags object = {}
param prefix string
param dbserverDatabaseName string

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

    mongodbDatabases: [
      {
        name: dbserverDatabaseName
      }
    ]
  }
}

output id string = databaseAccount.outputs.resourceId
output endpoint string  = databaseAccount.outputs.endpoint
