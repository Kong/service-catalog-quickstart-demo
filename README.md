# Kong Service Catalog Demo - Quickstart Guide

**Time:** 15-20 minutes

Experience Kong's Service Catalog by creating a realistic demo environment with GitHub repos, PagerDuty services, and sample APIs. This quickstart creates a complete demo setup and walks you through key Service Catalog features including service discovery, scorecard creation, and API governance.

## Prerequisites

- GitHub CLI (`gh`)
- Git
- `jq` (for JSON parsing)
- A GitHub personal access token with repo permissions
- Kong Konnect account
- (Optional) Free PagerDuty developer account

## Project Structure

```
kong-service-catalog-demo/
├── README.md                   # This file
├── setup.sh                    # One-click setup script
├── demo-assets/                # Template for the demo repository
│   ├── [OpenAPI specs]         # API specifications for each service
│   ├── services/               # Code for each service
│   └── .github/workflows/      # GitHub Actions workflows
└── scripts/
    ├── deck/                     # decK config for target Kong Konnect CP
        ├── backup/               # Stores any existing Kong Konnect CP config
    ├── setup-gateway-services.sh # Create gateway services in target CP with decK
    ├── setup-pagerduty.sh        # Create PagerDuty services via API
    └── cleanup.sh                # Cleanup script
```

## Demo Walkthrough

### Step 1: Initialize Demo Environment

Clone the repo locally and run the setup script to create your demo repository:

```bash
./setup.sh
```

First, provide the script the name of your target control plane in Kong Konnect. Please ensure you're okay with the configuration on this control plane being overwritten. Worst case, a backup of the existing config will be made and stored under the `/scripts/deck/backup/` directory.

Next, the script will ask for a Konnect Personal Access Token if it does not see one in the current terminal session.

Finally, the script will make sure you have the GitHub CLI (`gh`) installed and authenticated.

The script will:

- Create Kong Gateway Services in the target control plane you provided
- Create a new GitHub repository called "SC Demo" under your github profile
- Generate sample PRs, issues, and GitHub Actions for realistic repo activity

**Action Required:** When the script pauses, connect your GitHub integration in Kong Konnect Service Catalog. Follow the [docs here](https://developer.konghq.com/service-catalog/integrations/github/) to complete and then continue the script.

Proceed to step 2 while the script continues to run.

### Step 2: Create Services in Service Catalog

While the script runs, return to Service Catalog in Kong Konnect. Navigate to Services and create the following two services in Service Catalog by providing a name and description:

#### Service 1: "Core Platform Services"

**Description:** Manages the foundational platform services that handle core business entities (users, customers) and critical operations (payments)

#### Service 2: "Business Operation Services"

**Description:** Support business operations, reporting, and product management

### Step 3: Connect PagerDuty Integration (Optional)

Return to the script and optionally proceed with the PagerDuty portion of the setup. This requires a free developer account and API key.

If you decide to run the PagerDuty portion of the script, then you need to add the PagerDuty integration like you did previously with the Github integration. Documentation for this process is provided [here](https://developer.konghq.com/service-catalog/integrations/pagerduty/).

### Step 4: Map Resources to Services

After script completion, map the created resources to their respective services. You can learn more about how resource mapping works [here](https://developer.konghq.com/service-catalog/).

For this quickstart, we need to map the same Github monorepo resource to both services. Then we need to map Kong Gateway resources and PagerDuty resources to each service based on the mapping below:

#### Service 1: "Core Platform Services"

**APIs:**

- **User API** - Authentication, user profiles, identity management
- **Payment API** - Payment processing, billing, transactions
- **Customer API** - Customer data, CRM, legacy customer management

#### Service 2: "Business Operation Services"

**APIs:**

- **Analytics API** - Reporting, metrics, business intelligence
- **Inventory API** - Product catalog, stock management, inventory tracking

### Step 5: Create Scorecards

#### Documentation Scorecard

1. Navigate to **Scorecards** → **Create Scorecard**
2. Name: "API Documentation Standards"
3. Add rules:
   - **Documentation**: 1 or more documentation files required
   - **API Spec**: 1 or more API specs required
   - **API Spec Linting**: Enable rulesets:
     - ✅ OAS Recommended
     - ✅ OWASP Top 10
     - ✅ Documentation
4. Apply to: The two services we just created

#### Service Maturity Scorecard

1. Create scorecard: "Service Maturity Standards"
2. Configure the rules to match the image below
3. Apply to: The two services we just created

<img width="1677" alt="Screenshot 2025-06-27 at 12 20 31 PM" src="https://github.com/user-attachments/assets/712babf6-9f0f-4811-af55-30516d8e269e" />


### Step 6: Import API Specifications

Import OpenAPI specs into each service by navigating to each service, opening the **API Specs** tabs, add a new API spec, choose Github as the source, select the repo that setup script created, and select the API with the **Spec** dropdown.

The following still applies for which APIs belong to which services:

#### Service 1: "Core Platform Services"

- **User API** - Authentication, user profiles, identity management
- **Payment API** - Payment processing, billing, transactions
- **Customer API** - Customer data, CRM, legacy customer management

#### Service 2: "Business Operation Services"

- **Analytics API** - Reporting, metrics, business intelligence
- **Inventory API** - Product catalog, stock management, inventory tracking

However, only specs are available for the core platform service:

- **Core Platform Services**: Import 3 API specifications
- **Business Operation Services**: No specs to import initially

### Step 7: Refresh and Review Scorecards

By default, scorecard refresh every 15 minutes so we're going to force a manual refresh.

1. **Refresh Documentation Scorecard**: Open the documentation scorecard and save to trigger re-evaluation
2. **Merge PRs**: While documentation scorecard updates, navigate to the github repo that was created and merge 2 of 3 PRs created in your demo repository
3. **Refresh Service Maturity Scorecard**: Trigger re-evaluation after PR merges
4. **Review Results**: Examine both scorecards to see compliance status

## Expected Outcomes

After completing this demo, you'll have:

- A realistic GitHub repository with development activity
- (Optionally) A PagerDuty account with services and simulated activity
- Two services properly catalogued with associated resources
- Working scorecards that demonstrate API governance
- Experience with Service Catalog's key features including discovery, governance, and compliance tracking

## Cleanup

Run the cleanup script to remove the github repo in your account:

```bash
./scripts/cleanup.sh
```

## Next Steps

Begin evaluating how you can can integrate Service Catalog with your actual APIs and services. [Schedule a demo with our in-house experts](https://konghq.com/contact-sales) to learn how Service Catalog can help solve your organization’s use case.
