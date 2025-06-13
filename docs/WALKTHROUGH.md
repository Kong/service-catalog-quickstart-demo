# Kong Service Catalog Demo Walkthrough

**Time:** 15-20 minutes

## Prerequisites ✅

- Demo repository created with `setup.sh`
- Github integration setup when running `setup.sh`

## Phase 1: Setup and Discovery (10 minutes)

### 1.1 Connect Pagerduty Integration

1. Log into **Kong Konnect**
2. Navigate to **Service Catalog** (left sidebar)
3. Click **Integrations** → **Configure Integrations**
4. Click **Pagerduty** → **Add Configuration**
5. Authenticate with Pagerduty
6. Click **Save**

### 1.2 Create Services from resources

Navigate to **Service Catalog** → **Resources**. We will create two services managed by different teams by linking the relevant gateway services, pagerduty, and github repo resources.

**Service 1: "Core Platform Services"**

- User API - Authentication, user profiles, identity management
- Payment API - Payment processing, billing, transactions
- Customer API - Customer data, CRM, legacy customer management

Description: Manages the foundational platform services that handle core business entities (users, customers) and critical operations (payments)

**Service 2: "Business Operation Services"**

- Analytics API - Reporting, metrics, business intelligence
- Inventory API - Product catalog, stock management, inventory tracking

Rationale: Support business operations, reporting, and product management

### 1.3 Pull in relevant specs to each service

## Phase 2: Apply Scorecards (5 minutes)

### 2.1 Create Documentation Scorecard

1. Navigate to **Scorecards** → **Create Scorecard**
2. Name: "API Documentation Standards"
3. Add rules:
   - **Documentation**: 1 or more documentation files required
   - **API Spec**: 1 or more API specs required
   - **API Spec Linting**: Enable these rulesets:
     - ✅ OAS Recommended
     - ✅ OWASP Top 10
     - ✅ Documentation
4. Apply to: All services
5. Click **Save**

**Results:**

- ❌ **user-api**: Fails OWASP (no security definitions)
- ⚠️ **payment-api**: Fails versioning (outdated spec)
- ❌ **inventory-api**: No API specification
- ⚠️ **customer-api**: Deprecated
- ✅ **analytics-api**: Passes all checks

### 2.2 Create Best Practices Scorecard

1. Create another scorecard: "Kong Best Practices"
2. Add rules:
   - **Gateway Service**: Service must exist in Gateway
   - **Error Rate**: < 5% over 7 days
   - **Latency**: < 500ms average
   - **Authentication**: Required plugin
3. Apply to: All services

**Results:**

- ❌ All services initially fail (not in gateway)

### 2.2 Create Service Maturity Scorecard

1. Create another scorecard: "Kong Best Practices"

**Results:**

-

## Phase 3: Apply fixes

Update specs

Apply plugins

Resolve pagerduty incidents

Merge PRs

Add documentation
