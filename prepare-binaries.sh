#!/bin/bash

# Make the binaries executable
chmod +x xmlui-mcp

# On macOS, remove quarantine attribute if present
if [[ "$(uname)" == "Darwin" ]]; then
  xattr -d com.apple.quarantine xmlui-mcp 2>/dev/null || true
  echo "✓ Quarantine bits removed from MCP binaries"
fi
