# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Lint** (compile-checks Bicep without deploying):
```bash
az bicep build --file main.bicep
```

**Validate against a live resource group** (requires `az login`):
```bash
az deployment group validate \
  --resource-group rg-NSSDeployment-dev \
  --template-file main.bicep \
  --parameters environments/dev/main.bicepparam
```

**Preview changes (what-if)**:
```bash
# Via Azure CLI directly
az deployment group what-if \
  --resource-group rg-NSSDeployment-dev \
  --template-file main.bicep \
  --parameters environments/dev/main.bicepparam

# Via PowerShell script (preferred for local dev)
./scripts/Deploy-BicepStack.ps1 -Environment dev -WhatIf
```

**Deploy locally**:
```bash
./scripts/Deploy-BicepStack.ps1 -Environment dev      # deploy
./scripts/Deploy-BicepStack.ps1 -Environment staging
./scripts/Deploy-BicepStack.ps1 -Environment prod
```

The PowerShell script runs `az bicep build` (lint) automatically before any deploy or what-if.

## Architecture

### Scope & Entry Point

`main.bicep` targets `resourceGroup` scope. All resources must be deployed into one of the three pre-created resource groups: `rg-NSSDeployment-{dev|staging|prod}`.

Parameters flow: `environments/{env}/main.bicepparam` → `main.bicep` → child `modules/`.

### Module Layout

Modules live in `modules/{domain}/main.bicep`. All four domains exist as scaffolded stubs — uncomment and wire them in `main.bicep` as resources are added:

| Domain | Module path |
|--------|------------|
| networking | `modules/networking/main.bicep` |
| compute | `modules/compute/main.bicep` |
| security | `modules/security/main.bicep` |
| storage | `modules/storage/main.bicep` |

Each module receives `location`, `environmentName`, `projectName`, and `tags` as standard params.

### Environment-Specific Overrides

`environments/{env}/` is primarily for the `.bicepparam` file for that environment. Put shared artifact definitions under `modules/{domain}/`, and add environment-specific Bicep under `environments/{env}/` only when the divergence is real and the top-level composition explicitly calls it.

### CI/CD Pipeline

| Trigger | Workflow | What happens |
|---------|----------|--------------|
| Pull request to `main`/`develop` | `bicep-validate.yml` | Lint + validate + what-if across all three envs (matrix) |
| Push to `main` | `bicep-deploy.yml` | Sequential: dev → staging → prod (prod requires GitHub reviewer approval) |
| `workflow_dispatch` | `bicep-deploy.yml` | Deploy to a single chosen environment |

Authentication uses OIDC Workload Identity Federation — no long-lived credentials. Secrets required: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.

### Naming Convention

```
<type>-<projectName>-<environment>[-<instance>]
```

- All segments must be **lowercase**.
- `<type>` is the abbreviated Azure resource type (e.g. `vnet`, `nsg`, `kv`, `rg`, `st`).
- `<projectName>` and `<environment>` are always passed as module params — never derived from the resource group name or hardcoded.

Examples: `rg-nssdeployment-prod`, `kv-nssdeployment-dev-001`, `vnet-nssdeployment-staging`

**Bicep pattern** — use `toLower()` on both infix params so names are safe regardless of how callers pass them:

```bicep
param environmentName string
param projectName string

param vnetName string = 'vnet-${toLower(projectName)}-${toLower(environmentName)}'
param nsgName  string = 'nsg-${toLower(projectName)}-${toLower(environmentName)}'
```

Never derive resource names by parsing or replacing the resource group name — it creates a hidden coupling to the RG naming scheme and breaks cross-environment reuse.

## Bicep Conventions

- **`bicepconfig.json`** enforces the linter. Several rules are set to `error` (not just warning) and will fail CI: `outputs-should-not-contain-secrets`, `no-hardcoded-location`, `secure-secrets-in-params`, `max-params`, `max-resources`, `max-variables`, `max-outputs`, `max-asserts`, `use-recent-api-versions`.
- Formatting: 2-space indent, LF line endings, no trailing whitespace, final newline — all enforced by `bicepconfig.json`.
- Experimental features enabled in `bicepconfig.json`: `symbolicNameCodegen`, `assertions`, `deployCommands`, `localDeploy`.
- Never hardcode locations — always pass `location` as a parameter defaulting to `resourceGroup().location`.
- Outputs must not contain secrets (`@secure()` params must not be surfaced as outputs).
- `use-recent-api-versions` is enforced with `maxAgeInDays: 0`, so stale API versions fail lint rather than warning.
