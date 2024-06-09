metadata description = 'Creates an Azure Cosmos DB for MongoDB account.'
param name string
param location string = resourceGroup().location
param tags object = {}

param keyVaultName string
param connectionStringName string = 'AZURE-COSMOS-CONNECTION-STRING'

module cosmos '../../cosmos/cosmos-account.bicep' = {
  name: 'cosmos-account'
  params: {
    name: name
    location: location
    connectionStringName: connectionStringName
    keyVaultName: keyVaultName
    kind: 'MongoDB'
    tags: tags
  }
}

output connectionStringName string = cosmos.outputs.connectionStringName
output endpoint string = cosmos.outputs.endpoint
output id string = cosmos.outputs.id
