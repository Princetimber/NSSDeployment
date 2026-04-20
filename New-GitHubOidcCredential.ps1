#Requires -Version 7.0
<#
.SYNOPSIS
    Creates an Entra ID app registration with OIDC federated credentials for GitHub Actions.

.DESCRIPTION
    Performs the full OIDC setup for the NSSDeployment CI/CD pipeline in a single pass:
      1. Creates (or reuses) an app registration and service principal.
      2. Assigns Contributor + User Access Administrator on all three resource groups
         in parallel using ForEach-Object -Parallel.
      3. Adds federated credentials for push-to-main and pull-request events.
      4. Prints the three values required as GitHub Actions repository secrets.

.PARAMETER AppName
    Display name of the Entra ID app registration.
    Defaults to 'NSSDeployment-GitHubActions'.

.PARAMETER GitHubOrg
    GitHub organisation or user account that owns the repository.
    Defaults to 'Princetimber'.

.PARAMETER GitHubRepo
    GitHub repository name.
    Defaults to 'NSSDeployment'.

.PARAMETER Environments
    Resource group environment suffixes to assign roles on.
    Defaults to @('dev', 'staging', 'prod').

.EXAMPLE
    ./New-GitHubOidcCredential.ps1

.EXAMPLE
    ./New-GitHubOidcCredential.ps1 -AppName 'MyApp-CI' -GitHubOrg 'myorg' -GitHubRepo 'my-repo'

.NOTES
    Requires: Azure CLI (az) with an active authenticated session (az login).
    The signed-in account must have permission to create app registrations and
    assign roles (e.g. Owner or User Access Administrator at subscription level).
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [string]$AppName = 'NSSDeployment-GitHubActions',

    [Parameter()]
    [string]$GitHubOrg = 'Princetimber',

    [Parameter()]
    [string]$GitHubRepo = 'NSSDeployment',

    [Parameter()]
    [string[]]$Environments = @('dev', 'staging', 'prod')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Preflight ─────────────────────────────────────────────────────────────────

try   { $null = az version 2>&1; if ($LASTEXITCODE -ne 0) { throw } }
catch { throw 'Azure CLI not found. Install from: https://aka.ms/installazurecliwindows' }

$account        = az account show | ConvertFrom-Json
$subscriptionId = $account.id
$tenantId       = $account.tenantId

Write-Output "Subscription : $subscriptionId"
Write-Output "Tenant       : $tenantId"
Write-Output ''

# ── App registration ──────────────────────────────────────────────────────────

$existing = az ad app list --display-name $AppName --query '[0]' | ConvertFrom-Json

if ($existing) {
    Write-Output "Reusing existing app: $AppName ($($existing.appId))"
    $appId = $existing.appId
}
else {
    Write-Output "Creating app registration: $AppName"
    $app   = az ad app create --display-name $AppName | ConvertFrom-Json
    $appId = $app.appId
}

# ── Service principal ─────────────────────────────────────────────────────────

$sp = az ad sp show --id $appId 2>$null | ConvertFrom-Json
if (-not $sp) {
    Write-Output 'Creating service principal...'
    $sp = az ad sp create --id $appId | ConvertFrom-Json
}

$spObjectId = $sp.id
Write-Output "Service principal object ID: $spObjectId"
Write-Output ''

# ── Role assignments (parallel) ───────────────────────────────────────────────
# Contributor       — create/update all resources
# User Access Admin — needed to create the KV role assignment in main.bicep

$roles = @('Contributor', 'User Access Administrator')

Write-Output 'Assigning roles on resource groups (parallel)...'

$Environments | ForEach-Object -Parallel {
    $rg    = "rg-NSSDeployment-$_"
    $scope = "/subscriptions/$using:subscriptionId/resourceGroups/$rg"

    foreach ($role in $using:roles) {
        $existing = az role assignment list `
            --assignee $using:spObjectId `
            --role $role `
            --scope $scope `
            --query '[0].id' -o tsv 2>$null

        if ($existing) {
            Write-Output "  [skip] $role already assigned on $rg"
        }
        else {
            az role assignment create `
                --assignee $using:spObjectId `
                --role $role `
                --scope $scope `
                --output none
            Write-Output "  [ok]   $role -> $rg"
        }
    }
} -ThrottleLimit 6

Write-Output ''

# ── Federated credentials ─────────────────────────────────────────────────────

$credentials = @(
    @{
        name     = 'github-main'
        subject  = "repo:$GitHubOrg/${GitHubRepo}:ref:refs/heads/main"
        desc     = 'Push to main branch'
    }
    @{
        name     = 'github-prs'
        subject  = "repo:$GitHubOrg/${GitHubRepo}:pull_request"
        desc     = 'Pull request events'
    }
)

foreach ($cred in $credentials) {
    $exists = az ad app federated-credential list --id $appId `
        --query "[?name=='$($cred.name)'].name" -o tsv 2>$null

    if ($exists) {
        Write-Output "  [skip] Federated credential '$($cred.name)' already exists"
    }
    else {
        $body = @{
            name      = $cred.name
            issuer    = 'https://token.actions.githubusercontent.com'
            subject   = $cred.subject
            audiences = @('api://AzureADTokenExchange')
        } | ConvertTo-Json -Compress

        az ad app federated-credential create --id $appId --parameters $body --output none
        Write-Output "  [ok]   Federated credential '$($cred.name)' created ($($cred.desc))"
    }
}

Write-Output ''

# ── Output GitHub secrets ─────────────────────────────────────────────────────

Write-Output '─────────────────────────────────────────────'
Write-Output 'Add these to GitHub → Settings → Secrets → Actions:'
Write-Output ''
Write-Output "  AZURE_CLIENT_ID       = $appId"
Write-Output "  AZURE_TENANT_ID       = $tenantId"
Write-Output "  AZURE_SUBSCRIPTION_ID = $subscriptionId"
Write-Output '─────────────────────────────────────────────'
