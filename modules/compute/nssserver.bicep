/*
  Bicep module for deploying the NSS (Network Security Server) virtual machine in Azure.
  Creates a managed disk imported from a VHD blob, two network interfaces, and the VM itself.
  Networking resources (VNet, subnets, NSG) are referenced as existing — not created here.
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

@description('Required: primary network interface name (subnet1 — management).')
param nicName string

@description('Required: secondary network interface name (subnet2 — NSS traffic).')
param nic2Name string

@description('Required: name of the storage account holding the VHD blob.')
param storageAccountName string

@description('Required: resource ID of the source storage account holding the VHD.')
param storageAccountId string

@description('Required: static private IP address for the secondary network interface.')
param nic2PrivateIpAddress string

@description('Required: name of the virtual network to attach the NICs to.')
param vnetName string

@description('Required: name of the network security group to associate with both NICs.')
param nsgName string

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

// Blob URI for the VHD — no SAS needed; the storage account ID provides the
// authorization context for the Disk Import service within the same subscription.
var vhdBlobUri = 'https://${storageAccountName}.blob.${environment().suffixes.storage}/nss/znss_5_2_osdisk.vhd'

// ── Existing networking resources ─────────────────────────────────────────────

resource vnet 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  name: vnetName
}

resource subnet1 'Microsoft.Network/virtualNetworks/subnets@2025-05-01' existing = {
  parent: vnet
  name: 'subnet1'
}

resource subnet2 'Microsoft.Network/virtualNetworks/subnets@2025-05-01' existing = {
  parent: vnet
  name: 'subnet2'
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-05-01' existing = {
  name: nsgName
}

// ── Managed disk ──────────────────────────────────────────────────────────────

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

// ── Network interfaces ────────────────────────────────────────────────────────

resource nic 'Microsoft.Network/networkInterfaces@2025-05-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    networkSecurityGroup: {
      id: nsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet1.id
          }
        }
      }
    ]
  }
}

resource nic2 'Microsoft.Network/networkInterfaces@2025-05-01' = {
  name: nic2Name
  location: location
  tags: tags
  properties: {
    networkSecurityGroup: {
      id: nsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: nic2PrivateIpAddress
          subnet: {
            id: subnet2.id
          }
        }
      }
    ]
  }
}

// ── Virtual machine ───────────────────────────────────────────────────────────

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
        {
          id: nic2.id
          properties: {
            primary: false
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
