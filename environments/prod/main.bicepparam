using '../../main.bicep'

param environmentName = 'prod'
param location        = 'uksouth'
param projectName     = 'nssdeployment'

// ── Security ───────────────────────────────────────────────────────────────────
// Key Vault: kv-nssdeployment-prod
param sshPublicKeySecretName = 'ssh-public-key'
// Replace with your public key (e.g. contents of ~/.ssh/id_rsa.pub).
// For CI/CD use getSecret() once the Key Vault exists and the secret is populated:
//   param sshPublicKey = getSecret('07940160-ad0c-43f6-a228-ed5f3baaf990', 'rg-NSSDeployment-prod', 'kv-nssdeployment-prod', 'ssh-public-key')
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

// ── Compute ────────────────────────────────────────────────────────────────────
param vhdSasUri      = 'https://znssprodeu.blob.core.windows.net/?sv=2024-11-04&ss=b&srt=sco&sp=rltfx&se=2026-10-28T16:15:57Z&st=2025-10-29T08:00:57Z&spr=https&sig=Znec6n%2FZMgnadybvpXHV0HXZXC7YPNcdydXwck1c8K4%3D'
param storageAccountId = '/subscriptions/07940160-ad0c-43f6-a228-ed5f3baaf990/resourceGroups/rg-NSSDeployment-dev/providers/Microsoft.Storage/storageAccounts/znssprodeu'
param subnetId       = '/subscriptions/07940160-ad0c-43f6-a228-ed5f3baaf990/resourceGroups/rg-NSSDeployment-prod/providers/Microsoft.Network/virtualNetworks/vnet-nssdeployment-prod/subnets/subnet1'
param vmSize         = 'Standard_D4s_v3'

