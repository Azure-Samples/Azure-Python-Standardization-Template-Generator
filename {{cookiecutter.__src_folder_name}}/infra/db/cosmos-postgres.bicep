// {% set pg_version = 15 %}

param name string
param location string = resourceGroup().location
param tags object = {}
param prefix string
param dbserverDatabaseName string
var dbserverUser = 'citus'
@secure()
param dbserverPassword string

module dbserver '../core/database/cosmos/cosmos-pg-adapter.bicep' = {
  name: name
  params: {
    name: '${prefix}-postgresql'
    location: location
    tags: tags
    postgresqlVersion: '{{pg_version}}'
    administratorLogin: dbserverUser
    administratorLoginPassword: dbserverPassword
    databaseName: dbserverDatabaseName
    allowAzureIPsFirewall: true
    coordinatorServerEdition: 'BurstableMemoryOptimized'
    coordinatorStorageQuotainMb: 131072
    coordinatorVCores: 1
    nodeCount: 0
    nodeVCores: 4
  }
}
