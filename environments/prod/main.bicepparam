using '../../main.bicep'

param environmentName = 'prod'
param location        = 'uksouth'
param projectName     = 'nssdeployment'

// ── Security ───────────────────────────────────────────────────────────────────
// Key Vault: kv-nssdeployment-prod
param sshPublicKeySecretName = 'ssh-public-key'
// Replace with your public key (e.g. contents of ~/.ssh/id_rsa.pub).
// For CI/CD use getSecret() once the Key Vault exists:
//   param sshPublicKey = getSecret('<subscriptionId>', 'rg-NSSDeployment-prod', 'kv-nssdeployment-prod', 'ssh-public-key')
param sshPublicKey = ''

// ── Networking ─────────────────────────────────────────────────────────────────
// NSG: nsg-nssdeployment-prod | VNet: vnet-nssdeployment-prod | NAT GW: natgw-nssdeployment-prod

// Zscaler hub IP ranges for outbound NSG rules — replace with ranges from your Zscaler admin portal.
param destinationAddressPrefixes = [
  '185.46.212.0/24'
  '165.225.0.0/17'
  '104.129.192.0/20'
]

// Source = subnet CIDRs of this VNet (must match addressPrefixes in networkingSubnets below).
param sourceAddressPrefixes = [
  '10.2.1.0/24'
  '10.2.2.0/24'
]

// VNet address space.
param addressPrefixes = [
  '10.2.0.0/16'
]

// Subnets to create in the VNet. Names must match the string values in the subnets param below.
param networkingSubnets = [
  {
    name: 'subnet1'
    addressPrefix: '10.2.1.0/24'
  }
  {
    name: 'subnet2'
    addressPrefix: '10.2.2.0/24'
  }
]

// DNS servers for the VNet.
param dnsServers = [
  '168.63.129.16'
  '8.8.8.8'
]

// Subnets to associate with the NAT Gateway (NSS server egress subnet).
param natGatewaySubnets = [
  {
    name: 'subnet1'
    addressPrefix: '10.2.1.0/24'
  }
]

// ── Storage ────────────────────────────────────────────────────────────────────
param storageAccountName = 'stnssdeploymentprod'
param vnetName           = 'vnet-nssdeployment-prod'
param subnets            = ['subnet1', 'subnet2']
// Public IP allowed to access the storage account (deployer or jump-host IP).
param publicIpAddress    = '86.24.37.134'

// ── Compute ────────────────────────────────────────────────────────────────────
param vhdFileName = 'nssserver.vhd'
param vmSize      = 'Standard_D4s_v3'
// Subnet resource ID for the VM NIC — references subnet1 created by the networking module.
param subnetId    = '/subscriptions/07940160-ad0c-43f6-a228-ed5f3baaf990/resourceGroups/rg-NSSDeployment-prod/providers/Microsoft.Network/virtualNetworks/vnet-nssdeployment-prod/subnets/subnet1'
