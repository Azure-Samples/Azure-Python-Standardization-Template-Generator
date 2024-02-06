param name string
param location string = resourceGroup().location
param tags object = {}

param sku object
param storage object
@description('Database administrator login name')
@minLength(1)
param adminName string = 'mySqlAdmin'
@secure()
param adminPassword string
param databaseNames array = []
param allowAzureIPsFirewall bool = false
param allowAllIPsFirewall bool = false
param allowedSingleIPs array = []

@description('MySQL version')
@allowed([
  '5.7'
  '8.0.21'
])
param version string = '8.0.21'

@allowed([
  'Disabled'
  'ZoneRedundant'
  'SameZone'
])
param highAvailabilityMode string = 'Disabled'

resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2021-05-01' = {
  location: location
  tags: tags
  name: name
  sku: sku
  properties: {
    version: version
    administratorLogin: adminName
    administratorLoginPassword: adminPassword
    storage: storage
    highAvailability: {
      mode: highAvailabilityMode
    }
  }

  resource database 'databases' = [for name in databaseNames: {
    name: name
    properties: {
      charset: 'utf8'
      collation: 'utf8_general_ci'
    }
  }]

  resource firewall_all 'firewallRules' = if (allowAllIPsFirewall) {
    name: 'allow-all-IPs'
    properties: {
        startIpAddress: '0.0.0.0'
        endIpAddress: '255.255.255.255'
    }
  }

  resource firewall_azure 'firewallRules' = if (allowAzureIPsFirewall) {
    name: 'allow-all-azure-internal-IPs'
    properties: {
        startIpAddress: '0.0.0.0'
        endIpAddress: '0.0.0.0'
    }
  }

  resource firewall_single 'firewallRules' = [for ip in allowedSingleIPs: {
    name: 'allow-single-${replace(ip, '.', '')}'
    properties: {
        startIpAddress: ip
        endIpAddress: ip
    }
  }]

}

output domainName string = mysqlServer.properties.fullyQualifiedDomainName
