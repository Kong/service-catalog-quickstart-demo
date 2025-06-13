#!/bin/bash

REPO_NAME=$1

if [ -z "$REPO_NAME" ]; then
    echo "Usage: ./cleanup.sh <repo-name>"
    echo "Example: ./cleanup.sh kong-demo-apis-20241205-143022"
    exit 1
fi

echo "🧹 Cleaning up demo environment..."
echo ""
echo "This will delete the GitHub repository: $REPO_NAME"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

# Delete GitHub repository
gh repo delete $REPO_NAME --yes

echo "✅ Cleanup complete!"