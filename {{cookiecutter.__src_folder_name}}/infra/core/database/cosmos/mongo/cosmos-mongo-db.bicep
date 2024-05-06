metadata description = 'Creates an Azure Cosmos DB for MongoDB account with a database.'
param accountName string
param databaseName string
param location string = resourceGroup().location
param tags object = {}

param collections array = []
param connectionStringName string = 'AZURE-COSMOS-CONNECTION-STRING'
param keyVaultName string

module cosmos 'cosmos-mongo-account.bicep' = {
  name: 'cosmos-mongo-account'
  params: {
    name: accountName
    location: location
    keyVaultName: keyVaultName
    tags: tags
    connectionStringName: connectionStringName
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2022-08-15' = {
  name: '${accountName}/${databaseName}'
  tags: tags
  properties: {
    resource: { id: databaseName }
  }

  resource list 'collections' = [for collection in collections: {
    name: collection.name
    properties: {
      resource: {
        id: collection.id
        shardKey: { _id: collection.shardKey }
        indexes: [ { key: { keys: [ collection.indexKey ] } } ]
      }
    }
  }]

  dependsOn: [
    cosmos
  ]
}

output connectionStringName string = connectionStringName
output databaseName string = databaseName
output endpoint string = cosmos.outputs.endpoint
