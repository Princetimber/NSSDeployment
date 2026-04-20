/*
  Bicep module for deploying the NSS (Network Security Server) virtual machine in Azure.
  Creates a managed disk imported from a VHD blob, a network interface, and the VM itself.
*/

@description('Required: location for all resources.')
param location string = resourceGroup().location

@description('Required: name of the virtual machine.')
param vmName string

@description('Required: VM size.')
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

@description('Required: managed disk name.')
param diskName string

@description('Required: network interface name.')
param nicName string

@description('Required: full URI of the VHD blob to import (e.g. https://<account>.blob.core.windows.net/<container>/<file>.vhd).')
param vhdBlobUri string

@description('Required: resource ID of the storage account that holds the VHD.')
param storageAccountId string

@description('Required: resource ID of the subnet for the network interface.')
param subnetId string

@description('Optional: OS type of the VHD image.')
@allowed(['Linux'])
param osType string = 'Linux'

@description('Optional: environment name tag value (dev | staging | prod). It defaults to dev.')
param environmentName string = 'dev'

@description('Optional: display name for the DisplayName resource tag.')
param displayName string = 'NSS Server'

@description('Optional: owner name for the Owner resource tag.')
param ownerName string = ''

@description('Required: resource tags.')
param tags object = {
  environment: environmentName
  DisplayName: displayName
  Owner: ownerName
}


resource managedDisk 'Microsoft.Compute/disks@2025-01-02' = {
  name: diskName
  location: location
  tags: tags
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Import'
      sourceUri: vhdBlobUri
      storageAccountId: storageAccountId
    }
    osType: osType
    diskSizeGB: 512
    hyperVGeneration: 'V1'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2025-05-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: vmName
  location: location
  tags: tags
  // System-assigned identity allows the VM to authenticate to Key Vault
  // and retrieve the SSH public key secret at runtime without stored credentials
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'Attach'
        osType: osType
        managedDisk: {
          id: managedDisk.id
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

output vmId string = vm.id
output vmName string = vm.name
output nicPrivateIpAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
// Principal ID of the system-assigned managed identity — used to assign Key Vault Secrets User role
output vmPrincipalId string = vm.identity.principalId
