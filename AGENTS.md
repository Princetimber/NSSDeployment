# AGENTS.md

## Scope and entrypoints
- This repo is Azure Bicep IaC at **resource group** scope. The deployment flow is `environments/{env}/main.bicepparam` -> `main.bicep` -> `modules/*`.
- `main.bicep` is the only top-level entrypoint for deploy/validate/what-if.
- Current state matters: all module declarations in `main.bicep` are commented out, and `modules/{networking,compute,security,storage}/main.bicep` are scaffold stubs with `TODO` markers. Do **not** assume those resources are active until they are wired into `main.bicep`.

## Highest-value files
- `CLAUDE.md`: fuller repo guidance for commands, architecture, naming, and Bicep conventions. Keep it in sync with this file when workflows change.
- `scripts/Deploy-BicepStack.ps1`: preferred local workflow for preview/deploy; it runs `az bicep build` before `what-if` or `create`.
- `.github/workflows/bicep-validate.yml`: CI source of truth for validation order: **lint -> validate -> what-if** across `dev`, `staging`, and `prod`.
- `.github/workflows/bicep-deploy.yml`: CI source of truth for deployment order: push to `main` deploys **dev -> staging -> prod**; `workflow_dispatch` deploys a single chosen environment.
- `bicepconfig.json`: linter, formatting, and Bicep feature flags enforced by CI/local builds.

## Commands agents should use
- Lint only: `az bicep build --file main.bicep`
- Validate a live environment: `az deployment group validate --resource-group rg-NSSDeployment-dev --template-file main.bicep --parameters environments/dev/main.bicepparam`
- Preferred local preview: `./scripts/Deploy-BicepStack.ps1 -Environment dev -WhatIf`
- Preferred local deploy: `./scripts/Deploy-BicepStack.ps1 -Environment dev`
- If not using the script, follow the same order as CI: **build -> validate -> what-if -> create**.

## Environment and deployment gotchas
- Live validation and deploy commands require `az login` and pre-created resource groups named `rg-NSSDeployment-{dev|staging|prod}`.
- CI and GitHub deployments require OIDC secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.
- `environments/staging/main.bicepparam` and `environments/prod/main.bicepparam` pin `location` to `uksouth`; `dev` does not override `location` and inherits the resource group location.
- Keep standard artifact definitions in `modules/{domain}/`. Use `environments/{env}/{domain}/` only for true environment-specific overrides that are explicitly wired into the deployment composition.

## Bicep conventions that will trip agents up
- Never hardcode locations in resource definitions; pass `location` through params and default to `resourceGroup().location` when appropriate.
- Never surface secrets in outputs or pass secrets insecurely; `bicepconfig.json` treats `outputs-should-not-contain-secrets` and `secure-secrets-in-params` as errors.
- `bicepconfig.json` also sets `no-hardcoded-location`, `max-params`, `max-resources`, `max-variables`, `max-outputs`, `max-asserts`, and `use-recent-api-versions` to `error`.
- Formatting is enforced by config: 2-space indentation, LF endings, trimmed trailing whitespace, final newline.
- Naming convention is `<type>-NSSDeployment-<environment>[-<instance>]`.
- Stale API versions now fail lint (`use-recent-api-versions` with `maxAgeInDays: 0`), so use the latest stable API version when adding resources.
