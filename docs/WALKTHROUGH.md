# Kong Service Catalog Demo Walkthrough

**Time:** 15-20 minutes

## Prerequisites ✅

- Demo repository created with `setup.sh`
- Kong Konnect account
- Kong Gateway running (for gateway migration demo)

## Phase 1: Discovery (5 minutes)

### 1.1 Connect GitHub Integration

1. Log into **Kong Konnect**
2. Navigate to **Service Catalog** (left sidebar)
3. Click **Integrations** → **Configure Integrations**
4. Click **GitHub** → **Add Configuration**
5. Authenticate with GitHub
6. Select your demo repository (kong-demo-apis-TIMESTAMP)
7. Click **Save**

**What happens:**

- Service Catalog discovers 5 API services
- Automatically extracts OpenAPI specifications
- Shows service health overview

### 1.2 Review Discovery Dashboard

Navigate to **Service Catalog** → **Services**

You should see:

- 5 services discovered
- 2 services with API specifications
- 1 service marked as deprecated
- 2 services missing documentation

**Key talking points:**

- "Instant visibility into all APIs in our repository"
- "Found services we didn't know existed"
- "Immediately see which APIs lack documentation"

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

## Phase 3: Gateway Migration (5 minutes)

### 3.1 Review Current State

Show that scorecards reveal:

- No services are behind the gateway
- No authentication configured
- No rate limiting

### 3.2 Migrate Services

```bash
# Run from demo directory
./scripts/migrate-to-gateway.sh
```
