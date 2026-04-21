# Module: networking

Deploys the full networking stack for the NSS environment: Network Security Group, Virtual Network with subnets, and a NAT Gateway for deterministic outbound egress.

**Internal deploy order:** NSG → VNet → NAT Gateway (each step `dependsOn` the previous).

---

## Resources created

| Resource | Name pattern |
|----------|-------------|
| `Microsoft.Network/networkSecurityGroups` | `nsg-{projectName}-{env}` |
| `Microsoft.Network/virtualNetworks` | `vnet-{projectName}-{env}` |
| `Microsoft.Network/publicIPAddresses` | `natgw-{projectName}-{env}pubIp` |
| `Microsoft.Network/natGateways` | `natgw-{projectName}-{env}` |

---

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `location` | string | No | `resourceGroup().location` | Azure region |
| `environmentName` | string | No | `'dev'` | Environment identifier |
| `projectName` | string | **Yes** | — | Naming prefix |
| `ownerName` | string | No | `''` | Owner tag value |
| `tags` | object | No | derived | Resource tags |
| `destinationAddressPrefixes` | array | **Yes** | — | Zscaler hub IP ranges for outbound NSG rules |
| `sourceAddressPrefixes` | array | **Yes** | — | Subnet CIDRs of this VNet (source of outbound traffic) |
| `addressPrefixes` | array | **Yes** | — | VNet address space (e.g. `['10.0.0.0/16']`) |
| `subnets` | array | **Yes** | — | Subnet objects: `[{ name: 'subnet1', addressPrefix: '10.0.1.0/24' }]` |
| `dnsServers` | array | **Yes** | — | DNS servers for the VNet |
| `natGatewaySubnets` | array | **Yes** | — | Subnets to associate with NAT Gateway (same object shape as `subnets`) |

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `nsgId` | string | Resource ID of the NSG |
| `nsgName` | string | Name of the NSG |
| `vnetId` | string | Resource ID of the VNet |
| `vnetName` | string | Name of the VNet |
| `natGatewayId` | string | Resource ID of the NAT Gateway |
| `natGatewayName` | string | Name of the NAT Gateway |
| `publicIpId` | string | Resource ID of the NAT Gateway public IP |
| `publicIpName` | string | Name of the NAT Gateway public IP |

---

## NSG rules

| Rule | Direction | Protocol | Port | Source | Destination | Action |
|------|-----------|----------|------|--------|-------------|--------|
| Allow-SSH-Mgmt | Inbound | TCP | 22 | * | 10.2.1.0/24 (subnet1) | Allow |
| Allow-HTTPS-ZscalerHub | Outbound | TCP | 443 | subnet CIDRs | Zscaler hub IP ranges (`destinationAddressPrefixes` param) | Allow |
| Allow-Zscaler-RemoteSupport | Outbound | TCP | 443 | subnet CIDRs | 199.168.148.101 | Allow |
| Allow-DNS | Outbound | UDP | 53 | subnet CIDRs | * | Allow |
| Allow-NTP | Outbound | UDP | 123 | subnet CIDRs | * | Allow |

---

## Usage

```bicep
module networking './modules/networking/main.bicep' = {
  name: 'networkingDeploy'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    destinationAddressPrefixes: destinationAddressPrefixes  // Zscaler hub IPs
    sourceAddressPrefixes: sourceAddressPrefixes            // subnet CIDRs
    addressPrefixes: ['10.0.0.0/16']
    subnets: [
      { name: 'subnet1', addressPrefix: '10.0.1.0/24' }
      { name: 'subnet2', addressPrefix: '10.0.2.0/24' }
    ]
    dnsServers: ['168.63.129.16', '8.8.8.8']
    natGatewaySubnets: [
      { name: 'subnet1', addressPrefix: '10.0.1.0/24' }
    ]
  }
}
```
