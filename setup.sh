#!/bin/bash
set -e

echo "🚀 Kong Service Catalog Demo Setup"
echo "=================================="

# Check if running from repo root
if [ ! -f "scripts/deck/kong-config.yaml" ]; then
    echo "❌ Error: Please run this script from the repository root"
    exit 1
fi
# Save root directory for later
ORIGINAL_DIR=$(pwd)

# Clean up any existing temp directory from failed runs
if [ -d "local-repo" ]; then
    echo "⚠️  Found existing local-repo directory from previous run"
    echo "   Cleaning up..."
    rm -rf local-repo
fi

# Kong Konnect Configuration
echo ""
echo "📋 Kong Konnect Configuration"
echo "-----------------------------"

# Check for Konnect environment variables
if [ -z "$KONNECT_CONTROL_PLANE" ]; then
    while true; do
        echo "Enter your Konnect Control Plane name (Control Plane names are case sensitive):"
        read -r KONNECT_CONTROL_PLANE
        
        # Trim whitespace
        KONNECT_CONTROL_PLANE=$(echo "$KONNECT_CONTROL_PLANE" | xargs)
        
        if [ -n "$KONNECT_CONTROL_PLANE" ]; then
            break
        else
            echo "❌ Control Plane name is required and cannot be empty."
            echo ""
        fi
    done
    export KONNECT_CONTROL_PLANE
fi

if [ -z "$KONNECT_TOKEN" ]; then
    echo "Enter your Konnect Personal Access Token:"
    echo "(Get one from: https://cloud.konghq.com/global/account/tokens)"
    read -rs KONNECT_TOKEN
    export KONNECT_TOKEN
    echo ""
fi

echo "🔍 Testing Konnect connection..."
if deck gateway ping \
    --konnect-control-plane-name "$KONNECT_CONTROL_PLANE" \
    --konnect-token "$KONNECT_TOKEN" 2>/dev/null; then
    echo "✅ Successfully connected to Konnect on this control plane: $KONNECT_CONTROL_PLANE!"
else
    echo "❌ Failed to connect to Konnect. Please check your credentials and that control plane '$KONNECT_CONTROL_PLANE', matches a valid control plane in your Konnect org."
    exit 1
fi

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v gh >/dev/null 2>&1 || { echo "❌ GitHub CLI (gh) is required. Install from: https://cli.github.com/"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "❌ Git is required."; exit 1; }
command -v deck >/dev/null 2>&1 || { echo "❌ decK is required. Install from: https://docs.konghq.com/deck/latest/installation/"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "❌ jq is required."; exit 1; }

# Check GitHub authentication
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ Not authenticated with GitHub CLI"
    echo "   Run: gh auth login --scopes 'repo,workflow'"
    exit 1
fi

# Get scopes from auth status
echo "🔍 Verifying required scopes..."
auth_output=$(gh auth status 2>&1)

if echo "$auth_output" | grep -qw "repo" && echo "$auth_output" | grep -qw "workflow"; then
    echo "✅ All required scopes present"
else
    echo "⚠️  Missing required scopes"
    echo "Current auth status:"
    gh auth status
    echo ""
    echo "Please run: gh auth refresh --scopes 'repo,workflow'"
    exit 1
fi
echo "✅ GitHub authentication verified with required scopes"

# Setup git to use gh credentials
echo "🔧 Linking Git with GitHub CLI..."
if ! gh auth setup-git 2>/dev/null; then
    echo "⚠️  Warning: Could not automatically configure Git authentication"
    echo "   You may need to run: gh auth refresh --scopes repo"
    echo "   Or ensure you have the necessary permissions"
    exit 1
fi

echo "✅ git CLI authentication configured"

# Run Kong Gateway migration
echo ""
echo "🔄 Setting up Kong Gateway..."
echo "================================"
./scripts/setup-gateway-services.sh
if [ $? -ne 0 ]; then
    echo "❌ Kong Gateway setup failed"
    exit 1
fi
echo "✅ Kong Gateway setup complete"

# Generate unique repo name
GITHUB_USER=$(gh api user --jq .login)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPO_NAME="kong-demo-apis-${TIMESTAMP}"

echo "📦 Creating repository: $REPO_NAME"

# Create and clone repository
gh repo create $REPO_NAME --public --description "Kong Service Catalog Demo - API Services"
git clone "https://github.com/$GITHUB_USER/$REPO_NAME" local-repo
cd local-repo

# Copy demo assets
cp -r ../demo-assets/api-services/. .

echo "✅ Repository created successfully!"
echo ""
echo "🔗 Repository URL: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo ""
echo "======================================"
echo "⚠️  IMPORTANT: Link this repository in Service Catalog NOW"
echo "======================================"
echo ""
echo "1. Go to your Service Catalog"
echo "2. Navigate to Settings → Integrations → GitHub"
echo "3. Add this repository: $GITHUB_USERNAME/$REPO_NAME"
echo "4. Wait for the sync to complete"
echo ""
read -p "Press Enter once you've linked the repository in Service Catalog... "
echo ""
echo "Great! Continuing with setup..."
echo ""

# Initial commit - this now includes the .github/workflows/api-tests.yml
git add .
git commit -m "Initial repository setup with CI/CD"
git push origin main

# The workflow will automatically run on this push!

# Create historical commits and PRs for metrics
echo "📊 Creating historical data for scorecards..."

# Function to create historical PRs with proper dates
create_historical_pr() {
    local branch=$1
    local title=$2
    local days_ago=$3
    
    # Calculate the actual date
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        commit_date=$(date -v -${days_ago}d '+%Y-%m-%d %H:%M:%S')
    else
        # Linux
        commit_date=$(date -d "${days_ago} days ago" '+%Y-%m-%d %H:%M:%S')
    fi
    
    git checkout -b $branch
    echo "// Change made $days_ago days ago" >> services/analytics-api/README.md
    git add .
    
    # Use the calculated date
    GIT_AUTHOR_DATE="$commit_date" GIT_COMMITTER_DATE="$commit_date" git commit -m "$title"
    git push origin $branch
    
    # Create and immediately merge PR (skip approval)
    pr_url=$(gh pr create --title "$title" --body "Historical PR for metrics" --base main --head $branch)
    
    # Merge without approval - use admin merge to bypass branch protection if needed
    gh pr merge --merge --delete-branch --admin
}

# Create historical merged PRs
create_historical_pr "fix/analytics-docs" "Update analytics documentation" 30
create_historical_pr "feature/add-monitoring" "Add monitoring endpoints" 20
create_historical_pr "fix/rate-limits" "Increase rate limits" 15
create_historical_pr "chore/update-deps" "Update dependencies" 10

# Create long-running open PRs (for stale PR metrics)
git checkout main
git pull origin main
git checkout -b fix/user-api-auth
echo "# Work in progress - adding auth" >> services/user-api/README.md
git add . && git commit -m "WIP: Add authentication"
git push origin fix/user-api-auth
gh pr create --title "Add authentication to user API" --body "Still working on this..." --draft

git checkout -b fix/payment-errors
echo "# Investigating timeout issues" >> services/payment-api/README.md  
git add . && git commit -m "Debug payment timeouts"
git push origin fix/payment-errors
gh pr create --title "Fix Payment API Timeouts" --body "Complex issue, needs investigation"

# Trigger a couple more workflow runs
git checkout main
echo "// Trigger CI run 1" >> README.md && git add . && git commit -m "Trigger CI" && git push
echo "// Trigger CI run 2" >> README.md && git add . && git commit -m "Update README" && git push

# Create one more open PR
git checkout -b feature/improve-inventory
echo "# Inventory API improvements" >> services/inventory-api/README.md
git add . && git commit -m "Start inventory improvements"
git push origin feature/improve-inventory
gh pr create --title "Modernize Inventory API" --body "Long-running effort to improve the inventory service"

git checkout main

# Create labels before creating issues
echo "🏷️  Creating labels..."

# Create or update labels (using --force to update existing ones)
gh label create "security" --description "Security-related issues" --color "D73A4A" --force
gh label create "documentation" --description "Documentation improvements" --color "0075CA" --force
gh label create "api-spec" --description "API specification issues" --color "7057FF" --force
gh label create "infrastructure" --description "Infrastructure and deployment" --color "A2EEEF" --force
gh label create "ci-cd" --description "CI/CD pipeline issues" --color "C5DEF5" --force
gh label create "quality" --description "Code quality and standards" --color "BFD4F2" --force

# Create issues
echo "📝 Creating GitHub issues..."

gh issue create \
  --title "🚨 User API missing security definitions" \
  --body "The User API OpenAPI spec has no security schemes defined. This means the API documentation doesn't reflect that authentication is required." \
  --label "security,documentation"

gh issue create \
  --title "Payment API spec outdated" \
  --body "The OpenAPI spec shows v1.0 but the API is actually v2.0. This is causing integration issues for partners." \
  --label "documentation,api-spec"

gh issue create \
  --title "Inventory API missing OpenAPI specification" \
  --body "The inventory service has no OpenAPI documentation. This makes it difficult for teams to integrate." \
  --label "documentation"

gh issue create \
  --title "Multiple APIs not behind gateway" \
  --body "Services are directly exposed without going through Kong Gateway. Missing rate limiting, authentication, and monitoring." \
  --label "security,infrastructure"

gh issue create \
  --title "No API linting in CI/CD pipeline" \
  --body "OpenAPI specs are not validated in CI/CD. We should add spectral or similar to ensure specs meet standards." \
  --label "ci-cd,quality"

# PagerDuty Setup (Optional)
echo ""
echo "📟 PagerDuty Setup (Optional)"
echo "============================="
echo "Set up PagerDuty integration to see incident data in Service Catalog?"
echo "This will create sample incidents for your services."
echo ""
read -p "Do you want to set up PagerDuty? (y/N): " SETUP_PAGERDUTY
cd "$ORIGINAL_DIR"

if [[ "$SETUP_PAGERDUTY" =~ ^[Yy]$ ]]; then
    echo ""
    echo "To get your PagerDuty API key:"
    echo "1. Go to https://app.pagerduty.com/api_keys"
    echo "2. Click '+ Create New API Key'"
    echo "3. Give it a name like 'Kong Demo'"
    echo "4. Copy the key (you won't see it again!)"
    echo ""
    read -p "Enter your PagerDuty API Key: " PAGERDUTY_API_KEY
    
    # Validate the API key works
    echo "🔍 Validating PagerDuty API key..."
    if curl -s -H "Authorization: Token token=$PAGERDUTY_API_KEY" \
        -H "Accept: application/vnd.pagerduty+json;version=2" \
        https://api.pagerduty.com/abilities | grep -q '"abilities"'; then
        echo "✅ PagerDuty API key validated"
        
        # Create PagerDuty services and incidents
        echo "🚨 Creating PagerDuty services and sample incidents..."
        ./scripts/setup-pagerduty.sh "$PAGERDUTY_API_KEY"
        
    else
        echo "❌ Invalid PagerDuty API key. Skipping PagerDuty setup."
    fi
else
    echo "⏭️  Skipping PagerDuty setup"
fi

# Final summary
echo ""
echo "✅ Demo environment created successfully!"
echo ""
echo "📊 Created:"
echo "  - 4 merged PRs (with fast merge times)"
echo "  - 3 open PRs (including stale ones)"
echo "  - 5 GitHub issues"
echo "  - CI/CD workflows (2-3 second runs)"
echo ""
echo "📝 Repository URL: https://github.com/$GITHUB_USER/$REPO_NAME"
echo ""
echo "Continue following the README.md for next steps in setting up your Kong Konnect Service Catalog"
echo ""
echo "To clean up later, run: ./scripts/cleanup.sh $REPO_NAME"