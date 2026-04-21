using '../../main.bicep'

param environmentName = 'staging'
param location        = 'uksouth'
param projectName     = 'nssdeployment'

// ── Security ───────────────────────────────────────────────────────────────────
// Key Vault: kv-nssdeployment-staging
param sshPublicKeySecretName = 'ssh-public-key'
// Replace with your public key (e.g. contents of ~/.ssh/id_rsa.pub).
// For CI/CD use getSecret() once the Key Vault exists:
//   param sshPublicKey = getSecret('<subscriptionId>', 'rg-NSSDeployment-staging', 'kv-nssdeployment-staging', 'ssh-public-key')
param sshPublicKey = ''

// ── Networking ─────────────────────────────────────────────────────────────────
// NSG: nsg-nssdeployment-staging | VNet: vnet-nssdeployment-staging | NAT GW: natgw-nssdeployment-staging

// Zscaler hub IP ranges for outbound NSG rules — replace with ranges from your Zscaler admin portal.
param destinationAddressPrefixes = [
  '185.46.212.0/24'
  '165.225.0.0/17'
  '104.129.192.0/20'
]

// Source = subnet CIDRs of this VNet (must match addressPrefixes in networkingSubnets below).
param sourceAddressPrefixes = [
  '10.1.1.0/24'
  '10.1.2.0/24'
]

// VNet address space.
param addressPrefixes = [
  '10.1.0.0/16'
]

// Subnets to create in the VNet. Names must match the string values in the subnets param below.
param networkingSubnets = [
  {
    name: 'subnet1'
    addressPrefix: '10.1.1.0/24'
  }
  {
    name: 'subnet2'
    addressPrefix: '10.1.2.0/24'
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
    addressPrefix: '10.1.1.0/24'
  }
]

// ── Storage ────────────────────────────────────────────────────────────────────
param storageAccountName = 'stnssdeploymentstg'

