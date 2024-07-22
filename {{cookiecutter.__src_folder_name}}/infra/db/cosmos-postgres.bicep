// {% set pg_version = 15 %}

param name string
param location string = resourceGroup().location
param tags object = {}
param prefix string
param dbserverDatabaseName string
var dbserverUser = 'citus'
@secure()
param dbserverPassword string
param allowAllIpsFirewall bool = false
param allowAllAzureIpsFirewall bool = true

resource postgresCluster 'Microsoft.DBforPostgreSQL/serverGroupsv2@2023-03-02-preview' = {
  name: '${prefix}-postgresql'
  location: location
  tags: tags
  properties: {
    administratorLogin: dbserverUser
    administratorLoginPassword: dbserverPassword
    coordinatorServerEdition: 'BurstableMemoryOptimized'
    coordinatorStorageQuotainMb: 131072
    coordinatorVCores: 1
    postgresqlVersion: '{{pg_version}}'
    nodeCount: 0
    nodeVCores: 4
    databaseName: dbserverDatabaseName
  }

  resource firewall_all 'firewallRules' = if (allowAllIpsFirewall) {
    name: 'allow-all-IPs'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }

  resource firewall_azure 'firewallRules' = if (allowAllAzureIpsFirewall) {
    name: 'allow-all-azure-internal-IPs'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}

output dbserverDatabaseName string = dbserverDatabaseName
output dbserverUser string = dbserverUser
output dbserverDomainName string = postgresCluster.properties.serverNames[0].fullyQualifiedDomainName
