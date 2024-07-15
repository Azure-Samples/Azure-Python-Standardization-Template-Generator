// {% set pg_version = 15 %}

param name string
param location string = resourceGroup().location
param tags object = {}
param prefix string

// value is read-only in cosmos
var dbserverUser = 'admin${uniqueString(resourceGroup().id)}'
@secure()
param dbserverPassword string = ''
param dbserverDatabaseName string = ''

module flexibleServer 'br/public:avm/res/db-for-postgre-sql/flexible-server:0.1.6' = {
  name: name
  params: {
    name: '${prefix}-postgresql'
    location: location
    tags: tags
    skuName: 'Standard_B2s'
    tier: 'Burstable'
    version: '{{pg_version}}'
    administratorLogin: dbserverUser
    administratorLoginPassword: dbserverPassword
    databases: [{
      name: dbserverDatabaseName
    }]
    firewallRules: [
      {
        endIpAddress: '0.0.0.0'
        name: 'AllowAllWindowsAzureIps'
        startIpAddress: '0.0.0.0'
      }
    ]
  }
}

output dbserverDatabaseName string = dbserverDatabaseName
output dbserverUser string = dbserverUser
output dbserverDomainName string = flexibleServer.outputs.fqdn
