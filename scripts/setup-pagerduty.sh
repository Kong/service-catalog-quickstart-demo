#!/bin/bash
set -e

PAGERDUTY_API_KEY="$1"

# Set up proper headers for PagerDuty API v2
API_HEADERS=(
    -H "Authorization: Token token=$PAGERDUTY_API_KEY" 
    -H "Content-Type: application/json"
    -H "Accept: application/vnd.pagerduty+json;version=2"
)

echo "📦 Creating PagerDuty services..."

# Get the default escalation policy
ESCALATION_POLICY=$(curl -s "${API_HEADERS[@]}" \
    "https://api.pagerduty.com/escalation_policies?limit=1" | \
    jq -r '.escalation_policies[0].id')

if [ -z "$ESCALATION_POLICY" ]; then
    echo "❌ No escalation policy found. Please create one in PagerDuty first."
    exit 1
fi

# Function to create a PagerDuty service
create_pd_service() {
    local service_name="$1"
    local description="$2"
    
    # Check if service already exists
    existing_response=$(curl -s "${API_HEADERS[@]}" \
        "https://api.pagerduty.com/services?query=$(echo $service_name | sed 's/ /%20/g')")
    
    existing_service=$(echo "$existing_response" | \
        jq -r ".services[] | select(.name==\"$service_name\") | .id // empty")
    
    if [ -n "$existing_service" ]; then
        echo "  → Service already exists: $service_name ($existing_service)" >&2  # Send to stderr
        echo "$existing_service"  # Only output the ID to stdout
        return 0
    fi
    
    # Create new service
    response=$(curl -s "${API_HEADERS[@]}" \
        -X POST https://api.pagerduty.com/services \
        -d "{
            \"service\": {
                \"name\": \"$service_name\",
                \"description\": \"$description\",
                \"escalation_policy\": {
                    \"id\": \"$ESCALATION_POLICY\",
                    \"type\": \"escalation_policy_reference\"
                },
                \"alert_creation\": \"create_alerts_and_incidents\",
                \"status\": \"active\"
            }
        }")
    
    # Check for errors
    if echo "$response" | grep -q '"error"'; then
        echo "  ❌ Error creating service $service_name:" >&2
        echo "$response" | jq . >&2
        return 1
    fi
    
    service_id=$(echo "$response" | jq -r '.service.id // empty')
    if [ -z "$service_id" ]; then
        echo "  ❌ Failed to create service: $service_name" >&2
        echo "  Response: $response" >&2
        return 1
    fi
    
    echo "  ✓ Created service: $service_name ($service_id)" >&2  # Send to stderr
    echo "$service_id"  # Only output the ID to stdout
    return 0
}

# Create services for each API
echo ""
echo "Creating services..."
USER_SERVICE_ID=$(create_pd_service "User API" "Handles user authentication and profiles" || echo "")
PAYMENT_SERVICE_ID=$(create_pd_service "Payment API" "Processes payments and refunds" || echo "")
ANALYTICS_SERVICE_ID=$(create_pd_service "Analytics API" "Provides analytics and reporting" || echo "")
INVENTORY_SERVICE_ID=$(create_pd_service "Inventory API" "Manages product inventory" || echo "")
CUSTOMER_SERVICE_ID=$(create_pd_service "Customer API" "Legacy customer management" || echo "")

# Debug: Show what service IDs we got
echo ""
echo "Service IDs:"
echo "  USER_SERVICE_ID: ${USER_SERVICE_ID:-not created}"
echo "  PAYMENT_SERVICE_ID: ${PAYMENT_SERVICE_ID:-not created}"
echo "  ANALYTICS_SERVICE_ID: ${ANALYTICS_SERVICE_ID:-not created}"
echo "  INVENTORY_SERVICE_ID: ${INVENTORY_SERVICE_ID:-not created}"
echo "  CUSTOMER_SERVICE_ID: ${CUSTOMER_SERVICE_ID:-not created}"

# Check if we have at least one service
if [ -z "$PAYMENT_SERVICE_ID" ] || [ "$PAYMENT_SERVICE_ID" = "" ]; then
    echo "❌ No services were created successfully. Cannot create incidents."
    exit 1
fi

echo ""
echo "🚨 Creating sample incidents..."

# Try to get user email, but handle General Access tokens
USER_EMAIL=$(curl -s "${API_HEADERS[@]}" \
    "https://api.pagerduty.com/users/me" 2>/dev/null | jq -r '.user.email // empty')

if [ -z "$USER_EMAIL" ]; then
    echo "  ℹ️  Using General Access token - fetching first user..."
    # For General Access tokens, get the first user in the account
    USER_EMAIL=$(curl -s "${API_HEADERS[@]}" \
        "https://api.pagerduty.com/users?limit=1" | jq -r '.users[0].email // empty')
    
    if [ -z "$USER_EMAIL" ]; then
        echo "  ⚠️  No users found in account. Creating incidents without From header..."
    fi
fi

if [ -n "$USER_EMAIL" ]; then
    echo "  Using email: $USER_EMAIL"
fi

# Function to create an incident
create_incident() {
    local service_id="$1"
    local title="$2"
    local urgency="$3"
    local status="${4:-triggered}"  # Default to triggered if not specified
    
    # Build request data
    local request_data="{
        \"incident\": {
            \"type\": \"incident\",
            \"title\": \"$title\",
            \"service\": {
                \"id\": \"$service_id\",
                \"type\": \"service_reference\"
            },
            \"urgency\": \"$urgency\"
        }
    }"
    
    # Build headers array
    local incident_headers=("${API_HEADERS[@]}")
    if [ -n "$USER_EMAIL" ]; then
        incident_headers+=(-H "From: $USER_EMAIL")
    fi
    
    response=$(curl -s "${incident_headers[@]}" \
        -X POST https://api.pagerduty.com/incidents \
        -d "$request_data")
    
    if echo "$response" | grep -q '"incident"'; then
        incident_id=$(echo "$response" | jq -r '.incident.id')
        echo "  ✓ Created $urgency incident: $title (ID: $incident_id)"
        
        # Update status if needed
        if [ "$status" != "triggered" ]; then
            status_response=$(curl -s "${incident_headers[@]}" \
                -X PUT "https://api.pagerduty.com/incidents/$incident_id" \
                -d "{\"incident\": {\"type\": \"incident\", \"status\": \"$status\"}}")
            
            if echo "$status_response" | grep -q '"incident"'; then
                echo "    → Status updated to: $status"
            else
                echo "    ⚠️  Failed to update status to $status"
            fi
        fi
    else
        echo "  ❌ Failed to create incident: $title"
        echo "  Response: $response"
        
        # If it's the "Requester User Not Found" error, try without From header
        if echo "$response" | grep -q "1008"; then
            echo "  → Retrying without From header..."
            response=$(curl -s "${API_HEADERS[@]}" \
                -X POST https://api.pagerduty.com/incidents \
                -d "$request_data")
            
            if echo "$response" | grep -q '"incident"'; then
                incident_id=$(echo "$response" | jq -r '.incident.id')
                echo "  ✓ Created $urgency incident: $title (ID: $incident_id)"
                
                # Update status if needed (after retry)
                if [ "$status" != "triggered" ]; then
                    status_response=$(curl -s "${API_HEADERS[@]}" \
                        -X PUT "https://api.pagerduty.com/incidents/$incident_id" \
                        -d "{\"incident\": {\"type\": \"incident\", \"status\": \"$status\"}}")
                    
                    if echo "$status_response" | grep -q '"incident"'; then
                        echo "    → Status updated to: $status"
                    fi
                fi
            fi
        fi
    fi
}

# Create various incidents for different services
create_incident "$PAYMENT_SERVICE_ID" "High latency on payment processing" "high" "triggered" "10"
create_incident "$PAYMENT_SERVICE_ID" "Failed payment webhook delivery" "low" "resolved" "1440"
create_incident "$USER_SERVICE_ID" "Authentication service timeout" "high" "acknowledged" "30"
create_incident "$USER_SERVICE_ID" "Database connection pool exhausted" "high" "resolved" "2880"
create_incident "$ANALYTICS_SERVICE_ID" "Report generation OOM error" "low" "resolved" "4320"
create_incident "$INVENTORY_SERVICE_ID" "Inventory sync failed" "low" "triggered" "60"
create_incident "$CUSTOMER_SERVICE_ID" "Legacy API deprecation warnings" "low" "acknowledged" "120"

echo ""
echo "✅ PagerDuty setup complete!"
echo ""
echo "You can view your services and incidents at:"
echo "https://app.pagerduty.com/services"