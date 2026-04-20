# Repository Layout

## Ideal layout for this repo

```text
UWMe/
├── main.bicep
├── bicepconfig.json
├── modules/
│   ├── networking/
│   │   ├── main.bicep
│   │   ├── vnet.bicep
│   │   └── nsg.bicep
│   ├── storage/
│   │   └── main.bicep
│   ├── security/
│   │   └── main.bicep
│   └── compute/
│       └── main.bicep
├── environments/
│   ├── dev/
│   │   └── main.bicepparam
│   ├── staging/
│   │   └── main.bicepparam
│   └── prod/
│       └── main.bicepparam
├── scripts/
├── docs/
└── .github/workflows/
```

## Placement rules

- Put shared artifact definitions in `modules/{domain}/`.
- Keep `main.bicep` as the single top-level composition entrypoint.
- Keep environment-specific values in `environments/{env}/main.bicepparam`.
- Add `environments/{env}/{domain}/` only for true environment-specific overrides, and only when the deployment composition explicitly references them.
