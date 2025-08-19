#!/bin/bash

# XMLUI-MCP Binary Preparation Script
# Prepares the compiled binary for distribution and execution

set -e

BINARY_NAME="xmlui-mcp"
BIN_DIR="bin"
BINARY_PATH="${BIN_DIR}/${BINARY_NAME}"

echo "🔧 Preparing ${BINARY_NAME} binary..."

# Check if binary exists
if [ ! -f "${BINARY_PATH}" ]; then
    echo "❌ Binary not found at ${BINARY_PATH}"
    echo "   Run 'make build' or 'go build -o ${BINARY_PATH}' first"
    exit 1
fi

# Make the binary executable
echo "🔐 Setting executable permissions..."
chmod +x "${BINARY_PATH}"
echo "✅ Executable permissions set"

# On macOS, remove quarantine attribute if present
if [[ "$(uname)" == "Darwin" ]]; then
    echo "🍎 Removing macOS quarantine attribute..."
    if xattr -d com.apple.quarantine "${BINARY_PATH}" 2>/dev/null; then
        echo "✅ Quarantine attribute removed"
    else
        echo "ℹ️  No quarantine attribute found (this is normal)"
    fi
fi

# Verify the binary
echo "🔍 Verifying binary..."
if "${BINARY_PATH}" --help >/dev/null 2>&1 || [ $? -eq 1 ]; then
    echo "✅ Binary verification successful"
else
    echo "⚠️  Binary may not be properly prepared"
fi

echo "🎉 Binary preparation complete!"
echo "   📍 Location: ${BINARY_PATH}"
echo "   🚀 Ready to use!"
