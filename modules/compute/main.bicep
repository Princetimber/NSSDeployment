// Module : compute
// Purpose: Virtual machine and compute-related resources

targetScope = 'resourceGroup'

@description('Azure region.')
param location string = resourceGroup().location

@description('Environment name: dev | staging | prod.')
param environmentName string = 'dev'

@description('Project name used as a resource naming prefix.')
param projectName string

@description('Optional: owner name for the Owner resource tag.')
param ownerName string = ''

@description('Resource tags.')
param tags object = {
  environment: environmentName
  DisplayName: projectName
  Owner: ownerName
}

@description('Required: name of the storage account holding the VHD blob.')
param storageAccountName string

@description('Required: resource ID of the source storage account holding the VHD.')
param storageAccountId string

@description('Required: resource ID of subnet1 for the primary VM network interface.')
param subnetId string

@description('Required: resource ID of subnet2 for the secondary VM network interface.')
param nic2SubnetId string

@description('Required: static private IP address for the secondary network interface.')
param nic2PrivateIpAddress string

@description('Optional: VM size.')
@allowed([
  'Standard_DS1_v2'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
])
param vmSize string = 'Standard_D2s_v3'

@description('Optional: OS type of the VHD image.')
@allowed(['Linux'])
param osType string = 'Linux'

var vmName   = 'vm-${toLower(projectName)}-${toLower(environmentName)}'
var diskName = 'disk-${toLower(projectName)}-${toLower(environmentName)}'
var nicName  = 'nic1-${toLower(projectName)}-${toLower(environmentName)}'
var nic2Name = 'nic2-${toLower(projectName)}-${toLower(environmentName)}'

module nssServer './nssserver.bicep' = {
  name: '${projectName}-nssserver'
  params: {
    location: location
    tags: tags
    ownerName: ownerName
    environmentName: environmentName
    vmName: vmName
    diskName: diskName
    nicName: nicName
    nic2Name: nic2Name
    vmSize: vmSize
    osType: osType
    storageAccountName: storageAccountName
    storageAccountId: storageAccountId
    subnetId: subnetId
    nic2SubnetId: nic2SubnetId
    nic2PrivateIpAddress: nic2PrivateIpAddress
  }
}

output vmId string = nssServer.outputs.vmId
output vmName string = nssServer.outputs.vmName
output nicPrivateIpAddress string = nssServer.outputs.nicPrivateIpAddress
output vmPrincipalId string = nssServer.outputs.vmPrincipalId
