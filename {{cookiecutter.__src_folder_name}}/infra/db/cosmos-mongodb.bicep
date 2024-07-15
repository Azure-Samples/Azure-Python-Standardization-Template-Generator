param name string
param location string = resourceGroup().location
param tags object = {}
param prefix string
param keyVaultName string
param dbserverDatabaseName string

module dbserver '../core/database/cosmos/mongo/cosmos-mongo-db.bicep' = {
  name: name
  params: {
    accountName: '${take(prefix, 36)}-mongodb' // Max 44 characters
    location: location
    databaseName: dbserverDatabaseName
    tags: tags
    keyVaultName: keyVaultName
  }
}
