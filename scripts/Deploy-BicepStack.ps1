<#
.SYNOPSIS
Deploys the Bicep stack to a target environment.

.DESCRIPTION
Wraps az deployment group create with pre-flight Bicep lint and optional what-if
preview. Intended for local developer use and emergency manual deployments outside
of the CI/CD pipeline.

.PARAMETER Environment
Target environment: dev, staging, or prod.

.PARAMETER ResourceGroup
Resource group name. Defaults to rg-NSSDeployment-<Environment>.

.PARAMETER WhatIf
Runs az deployment group what-if without deploying.

.EXAMPLE
./Deploy-BicepStack.ps1 -Environment dev

.EXAMPLE
./Deploy-BicepStack.ps1 -Environment prod -WhatIf

.NOTES
Requires: Azure CLI (az) with an active authenticated session (az login).
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter()]
    [string]$ResourceGroup = "rg-NSSDeployment-$Environment",

    [Parameter()]
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try   { $null = az version 2>&1; if ($LASTEXITCODE -ne 0) { throw } }
catch { throw 'Azure CLI not found. See: https://aka.ms/installazurecliwindows' }

$repoRoot     = Split-Path -Parent $PSScriptRoot
$templateFile = Join-Path $repoRoot 'main.bicep'
$paramFile    = Join-Path $repoRoot "environments/$Environment/main.bicepparam"

foreach ($f in $templateFile, $paramFile) {
    if (-not (Test-Path $f)) { throw "File not found: $f" }
}

az bicep build --file $templateFile
if ($LASTEXITCODE -ne 0) { throw 'Bicep lint failed.' }

$deploymentName = "NSSDeployment-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

if ($WhatIf) {
    Write-Output "What-if: $Environment -> $ResourceGroup"
    az deployment group what-if `
        --resource-group $ResourceGroup `
        --template-file $templateFile `
        --parameters $paramFile
}
else {
    if (-not $PSCmdlet.ShouldProcess($ResourceGroup, "Deploy ($Environment)")) { return }
    Write-Output "Deploying '$deploymentName' to $ResourceGroup"
    az deployment group create `
        --name $deploymentName `
        --resource-group $ResourceGroup `
        --template-file $templateFile `
        --parameters $paramFile
    if ($LASTEXITCODE -ne 0) { throw "Deployment failed: $Environment" }
    Write-Output 'Deployment complete.'
}
