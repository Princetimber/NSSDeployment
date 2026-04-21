@description('Required:network security group location')
param location string = resourceGroup().location

@description('Required:name of the network security group to create.This must be unique within the resource group and can not be changed after creation. It defaults to the resource group name prefixed with nsg.')
param name string = '${toLower(replace(resourceGroup().name, 'enguksouthrg', '-'))}nsg'

@description('Required: source address prefixes, which includes the IP address range or CIDR block for the source of the rule. This can be internet, virtual network, subnet, or IP address or Public IP Address based on the service.')
param sourceAddressPrefixes array

@description('Required: destination address prefix. This can also be a CIDR block, virtual network, or service tag or Ip Address based on the service.')
param destinationAddressPrefixes array

@description('Optional: environment name for the Environment resource tag.')
param environmentName string = 'Dev'

@description('Optional: owner name for the Owner resource tag.')
param ownerName string

@description('Optional:tags of the network security group to create.')
param tags object = {
  displayName: 'Network Security Group'
  Environment: environmentName
  Owner: ownerName
}
//Inbound security rule collection

var securityRules = [
  {
    name: 'Allow_HTTPS_Inbound'
    properties: {
      priority: 100
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
      description: 'Allow inbound HTTPS traffic'
    }
  }
  {
    name: 'Allow_HTTP_Inbound'
    properties: {
      priority: 110
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '80'
      description: 'Allow inbound HTTP traffic'
    }
  }
  {
    name: 'Allow_SSH_Inbound'
    properties: {
      priority: 120
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '22'
      description: 'Allow inbound SSH traffic'
    }
  }
  {
    name: 'Allow_NSS_Zscaler_Hub_Outbound'
    properties: {
      priority: 130
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefixes: sourceAddressPrefixes
      sourcePortRange: '*'
      destinationAddressPrefixes: destinationAddressPrefixes
      destinationPortRange: '443'
      description: 'Allow outbound traffic to NSS Zscaler Hub'
    }
  }
  {
    name:'Allow_Zscaler_CertificateAuthority_Outbound'
    properties: {
      priority: 140
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefixes: sourceAddressPrefixes
      sourcePortRange: '*'
      destinationAddressPrefixes: destinationAddressPrefixes
      destinationPortRange: '443'
      description: 'Allow outbound traffic to Zscaler Certificate Authority'
    }
  }
  {
    name:'Allow_Zscaler_Software_Updates_Outbound'
    properties: {
      priority: 150
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefixes: sourceAddressPrefixes
      sourcePortRange: '*'
      destinationAddressPrefixes: destinationAddressPrefixes
      destinationPortRange: '443'
      description: 'Allow outbound traffic to Zscaler Software Updates'
    }
  }
  {
    name:'Allow_Zscaler_Remote_Support_Outbound'
    properties: {
      priority: 160
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefixes: sourceAddressPrefixes
      sourcePortRange: '*'
      destinationAddressPrefixes: '199.168.148.101'
      destinationPortRange: '12002'
      description: 'Allow outbound traffic to Zscaler Remote Support'
    }
  }
  {
    name:'Allow_DNS_Outbound'
    properties: {
      priority: 170
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Udp'
      sourceAddressPrefixes: sourceAddressPrefixes
      sourcePortRange: '*'
      destinationAddressPrefixes: '*'
      destinationPortRange: '53'
      description: 'Allow outbound DNS traffic'
    }
  }
  {
    name:'Allow_NTP_Outbound'
    properties: {
      priority: 180
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Udp'
      sourceAddressPrefixes: sourceAddressPrefixes
      sourcePortRange: '*'
      destinationAddressPrefixes: '*'
      destinationPortRange: '123'
      description: 'Allow outbound NTP traffic'
    }
  }
]

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    securityRules:[
      for rule in securityRules: {
        name: rule.name
        properties: rule.properties
      }
    ]
  }
}

output nsgId string = nsg.id
output nsgName string = nsg.name
