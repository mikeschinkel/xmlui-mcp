#!/bin/bash

# Distribution package creation script
# Creates tar.gz packages for all built platforms

set -e

BINARY_NAME="xmlui-mcp"
DIST_DIR="dist"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "Error: Cannot create distribution with uncommitted changes"
    echo "Please commit or stash your changes first"
    exit 1
fi

# Get version from git or use "dev"
VERSION=$(git describe --tags --always 2>/dev/null || echo "dev")

echo "Creating distribution packages..."

for dir in ${DIST_DIR}/*/; do
    if [ -d "$dir" ]; then
        platform=$(basename "$dir")
        echo "Creating package for $platform..."
        
        # Copy additional files to platform directory
        cp README.md "$dir/" 2>/dev/null || true
        cp scripts/analytics-helper.sh "$dir/" 2>/dev/null || true
        cp scripts/prepare-binary.sh "$dir/" 2>/dev/null || true
        
        # Create tar.gz package
        cd "$dir"
        tar -czf "../${BINARY_NAME}-${VERSION}-${platform}.tar.gz" .
        cd - > /dev/null
        
        echo "✓ Created ${DIST_DIR}/${BINARY_NAME}-${VERSION}-${platform}.tar.gz"
    fi
done

echo "✓ Distribution packages created"