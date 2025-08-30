#!/bin/bash

# Test workflow for Gojira

echo "=== Testing Gojira Workflow ==="

# Set up environment
GATEWAY_FOLDER="./examples/configs"
ENV_NAME="dev"
CLUSTER_FILE="./test/clusters-docker.yaml"

echo "1. Running lint validation..."
bundle exec gojira env lint -f "$GATEWAY_FOLDER" -n "$ENV_NAME" -c "$CLUSTER_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Lint validation passed"
else
    echo "✗ Lint validation failed"
    exit 1
fi

echo ""
echo "2. Generating Kong configurations..."

# Generate for PCI Delhi
echo "   - Generating PCI Delhi config..."
bundle exec gojira env generate -g "$GATEWAY_FOLDER" -n "$ENV_NAME" -f "$CLUSTER_FILE" -c pci -d delhi

# Generate for Non-PCI Delhi  
echo "   - Generating Non-PCI Delhi config..."
bundle exec gojira env generate -g "$GATEWAY_FOLDER" -n "$ENV_NAME" -f "$CLUSTER_FILE" -c non-pci -d delhi

# Generate for PCI Mumbai
echo "   - Generating PCI Mumbai config..."
bundle exec gojira env generate -g "$GATEWAY_FOLDER" -n "$ENV_NAME" -f "$CLUSTER_FILE" -c pci -d mumbai

# Generate for Non-PCI Mumbai
echo "   - Generating Non-PCI Mumbai config..."
bundle exec gojira env generate -g "$GATEWAY_FOLDER" -n "$ENV_NAME" -f "$CLUSTER_FILE" -c non-pci -d mumbai

echo ""
echo "3. Generated files:"
ls -la examples/configs/generated/

echo ""
echo "=== Test Complete ===