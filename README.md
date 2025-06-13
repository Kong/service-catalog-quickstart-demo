# Kong Service Catalog Demo - Quickstart Guide

**Time:** 15-20 minutes

## Project Structure

```
kong-service-catalog-demo/
├── README.md # This file
├── setup.sh # One-click setup script
├── demo-assets/
│ ├── services/ # Template for the monorepo
│ │ └── [service directories with OpenAPI specs]
│ ├── kong-config.yaml # decK configuration
│ └── .github/workflows # GitHub actions to run
├── scripts/
│ ├── migrate-to-gateway.sh # Gateway migration using decK
│ └── cleanup.sh # Cleanup script
└── docs/
| └── WALKTHROUGH.md # Step-by-step demo guide
```

## Prerequisites

- GitHub CLI (gh) - Install guide
- Git
- decK (Kong's declarative config tool) - Install guide
- jq (for JSON parsing)
- A GitHub personal access token with repo permissions
- Kong Konnect account
- Kong Gateway running (for gateway migration demo)
- (Optional) PagerDuty developer account for advanced demo
