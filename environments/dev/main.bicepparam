using '../../main.bicep'

param environmentName = 'dev'
param location        = 'uksouth'
param projectName     = 'nssdeployment'

// ── Security ───────────────────────────────────────────────────────────────────
// Key Vault: kv-nssdeployment-dev
param sshPublicKeySecretName = 'ssh-public-key'
// Injected at deploy time by GitHub Actions (SSH_PUBLIC_KEY env secret) — do not hardcode real keys here.
param sshPublicKey = ''

// ── Networking ─────────────────────────────────────────────────────────────────
// NSG: nsg-nssdeployment-dev | VNet: vnet-nssdeployment-dev | NAT GW: natgw-nssdeployment-dev

// Zscaler hub IP ranges for outbound NSG rules — replace with ranges from your Zscaler admin portal.
param destinationAddressPrefixes = [
  '104.129.193.87'
  '104.129.195.87'
  '104.129.193.106'
  '104.129.197.106'
  '104.129.197.87'
]

// Source = subnet CIDRs of this VNet (must match addressPrefixes in networkingSubnets below).
param sourceAddressPrefixes = [
  '10.0.1.0/24'
  '10.0.2.0/24'
]

// VNet address space.
param addressPrefixes = [
  '10.0.0.0/16'
]

// Subnets to create in the VNet. Names must match the string values in the subnets param below.
param networkingSubnets = [
  {
    name: 'subnet1'
    addressPrefix: '10.0.1.0/24'
  }
  {
    name: 'subnet2'
    addressPrefix: '10.0.2.0/24'
  }
  {
    name: 'AzureBastionSubnet'
    addressPrefix: '10.0.3.0/26'
  }
]

// Bastion subnet CIDR — must match the AzureBastionSubnet entry above.
param bastionSubnetAddressPrefix = '10.0.3.0/26'

// DNS servers for the VNet.
param dnsServers = [
  '168.63.129.16'
  '8.8.8.8'
]

// Subnets to associate with the NAT Gateway (NSS server egress subnet).
param natGatewaySubnets = [
  {
    name: 'subnet1'
    addressPrefix: '10.0.1.0/24'
  }
]

// ── Storage ────────────────────────────────────────────────────────────────────
param storageAccountName   = 'stnssdeploymentdev'
param storageNewOrExisting = 'existing'

// ── Compute ────────────────────────────────────────────────────────────────────
// vhdSasUri is NOT set here — generated at deploy time by the workflow using the
// storage account key, to avoid committing a SAS token to the repository.
// storageAccountId is derived from the storage module output (not a top-level param).
// Subnet resource ID for the VM NIC.
// subnetId / nic2SubnetId are resolved internally via existing resource references
// (vnet-nssdeployment-dev / subnet1 + subnet2) — not needed as top-level params.
param nic2PrivateIpAddress = '10.0.2.5'
param vmSize       = 'Standard_D2s_v3'
