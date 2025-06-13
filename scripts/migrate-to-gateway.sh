#!/bin/bash
set -e

echo "🔐 Migrating APIs to Kong Gateway..."
echo ""

# Check if running from repo root
if [ ! -f "kong-config.yaml" ]; then
    echo "❌ Error: kong-config.yaml not found"
    echo "   Please run this script from the repository root"
    exit 1
fi

# Load environment variables safely
if [ -f .env ]; then
    # Source the .env file properly (handles comments and spaces)
    set -a  # automatically export all variables
    source .env
    set +a  # turn off automatic export
else
    echo "❌ No .env file found. Please run setup.sh first."
    exit 1
fi

# Validate environment variables
if [ -z "$KONNECT_CONTROL_PLANE" ] || [ -z "$KONNECT_TOKEN" ]; then
    echo "❌ Error: Missing required environment variables"
    echo "   Please set:"
    echo "   - KONNECT_CONTROL_PLANE"
    echo "   - KONNECT_TOKEN"
    exit 1
fi

# Check if deck is installed
if ! command -v deck &> /dev/null; then
    echo "❌ deck CLI is required but not installed."
    echo "   Install from: https://docs.konghq.com/deck/latest/installation/"
    exit 1
fi

# Test Konnect connection
echo "📡 Connecting to Kong Konnect..."
echo "   Control Plane: $KONNECT_CONTROL_PLANE"

if ! deck gateway ping \
    --konnect-control-plane-name "$KONNECT_CONTROL_PLANE" \
    --konnect-token "$KONNECT_TOKEN"; then
    echo "❌ Cannot connect to Kong Konnect"
    echo "   Please check your KONNECT_TOKEN and KONNECT_CONTROL_PLANE"
    exit 1
fi

# Backup current configuration
echo "💾 Backing up current Kong configuration..."
deck gateway dump \
    --konnect-control-plane-name "$KONNECT_CONTROL_PLANE" \
    --konnect-token "$KONNECT_TOKEN" \
    -o "scripts/deck-backup/cp-${KONNECT_CONTROL_PLANE}-backup.yaml"

# Apply new configuration
echo "🚀 Applying gateway configuration..."

echo "📋 Configuration:"
echo "  Control Plane: $KONNECT_CONTROL_PLANE"
echo "  Config File: kong-config.yaml"
echo ""

# Sync to Kong Gateway
echo "🔄 Syncing configuration to Kong Konnect..."
deck gateway sync kong-config.yaml \
    --konnect-control-plane-name "$KONNECT_CONTROL_PLANE" \
    --konnect-token "$KONNECT_TOKEN"

echo ""
echo "✅ Migration complete!"
echo ""
echo "📊 Services now protected by Kong Gateway:"
echo "  - user-api     (Key Authentication + Rate Limiting)"
echo "  - payment-api  (Basic Auth + Rate Limiting)"  
echo "  - analytics-api (OAuth2 + Rate Limiting + CORS)"
echo ""
echo "⚠️  Services still unprotected:"
echo "  - inventory-api"
echo "  - customer-api"
echo ""
echo "These will be flagged by the Kong Best Practices scorecard!"