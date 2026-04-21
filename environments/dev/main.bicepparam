using '../../main.bicep'

param environmentName = 'dev'
param location        = 'uksouth'
param projectName     = 'nssdeployment'

// ── Security ───────────────────────────────────────────────────────────────────
// Key Vault: kv-nssdeployment-dev
param sshPublicKeySecretName = 'ssh-public-key'
// Replace with your public key (e.g. contents of ~/.ssh/id_rsa.pub).
// For CI/CD use getSecret() once the Key Vault exists and the secret is populated:
//   param sshPublicKey = getSecret('07940160-ad0c-43f6-a228-ed5f3baaf990', 'rg-NSSDeployment-dev', 'kv-nssdeployment-dev', 'ssh-public-key')
param sshPublicKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIARcqG6gkdopG6LKR8XcguVUzZob9hyTjLyCyalmFv1i zadmin@mymachines'

// ── Networking ─────────────────────────────────────────────────────────────────
// NSG: nsg-nssdeployment-dev | VNet: vnet-nssdeployment-dev | NAT GW: natgw-nssdeployment-dev

// Zscaler hub IP ranges for outbound NSG rules — replace with ranges from your Zscaler admin portal.
param destinationAddressPrefixes = [
  '185.46.212.0/24'
  '165.225.0.0/17'
  '104.129.192.0/20'
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
param subnetId     = '/subscriptions/07940160-ad0c-43f6-a228-ed5f3baaf990/resourceGroups/rg-NSSDeployment-dev/providers/Microsoft.Network/virtualNetworks/vnet-nssdeployment-dev/subnets/subnet1'
param nic2SubnetId         = '/subscriptions/07940160-ad0c-43f6-a228-ed5f3baaf990/resourceGroups/rg-NSSDeployment-dev/providers/Microsoft.Network/virtualNetworks/vnet-nssdeployment-dev/subnets/subnet2'
param nic2PrivateIpAddress = '10.0.2.5'
param vmSize       = 'Standard_D2s_v3'
