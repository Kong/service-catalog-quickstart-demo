#!/bin/bash
set -e

echo "🔐 Setting up Gateway Services in Kong Konnect..."
echo ""

# Validate environment variables
if [ -z "$KONNECT_CONTROL_PLANE" ] || [ -z "$KONNECT_TOKEN" ]; then
    echo "❌ Error: Missing required environment variables"
    echo "   Please set:"
    echo "   - KONNECT_CONTROL_PLANE"
    echo "   - KONNECT_TOKEN"
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