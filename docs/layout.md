# Repository Layout

## Ideal layout for this repo

```text
NSSDeployment/
├── main.bicep
├── bicepconfig.json
├── modules/
│   ├── networking/
│   │   ├── main.bicep
│   │   ├── nsg.bicep
│   │   ├── vnet.bicep
│   │   └── natgw.bicep
│   ├── security/
│   │   ├── main.bicep
│   │   └── keyvault.bicep
│   ├── storage/
│   │   ├── main.bicep
│   │   └── storage.bicep
│   └── compute/
│       ├── main.bicep
│       └── nssserver.bicep
├── environments/
│   ├── dev/main.bicepparam
│   ├── staging/main.bicepparam
│   └── prod/main.bicepparam
├── scripts/
│   └── Deploy-BicepStack.ps1
├── docs/
│   ├── architecture.md
│   └── layout.md
└── .github/workflows/
    ├── bicep-validate.yml
    └── bicep-deploy.yml
```

## Placement rules

- Put shared artifact definitions in `modules/{domain}/`.
- Keep `main.bicep` as the single top-level composition entrypoint.
- Keep environment-specific values in `environments/{env}/main.bicepparam`.
- Add `environments/{env}/{domain}/` only for true environment-specific overrides, and only when the deployment composition explicitly references them.
