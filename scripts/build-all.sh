#!/bin/bash

# XMLUI-MCP Cross-Platform Build Script
# Builds binaries for all supported platforms

set -e

DIST_DIR="dist"

echo "🏗️  Building xmlui-mcp for all supported platforms..."
echo ""

# Platform configurations: "OS/ARCH:DisplayName"
platforms=(
    "linux/amd64:Linux x64"
    "linux/arm64:Linux ARM64"
    "darwin/amd64:macOS Intel"
    "darwin/arm64:macOS Apple Silicon"
    "windows/amd64:Windows x64"
)

total=${#platforms[@]}
current=0

for platform_config in "${platforms[@]}"; do
    current=$((current + 1))
    
    # Parse platform configuration
    platform="${platform_config%%:*}"
    display_name="${platform_config##*:}"
    
    GOOS="${platform%/*}"
    GOARCH="${platform#*/}"
    
    output_dir="${DIST_DIR}/${GOOS}-${GOARCH}"
    
    echo "🔨 [${current}/${total}] Building for ${display_name} (${GOOS}/${GOARCH})..."
    
    # Use the centralized build script
    ./scripts/build.sh "${GOOS}" "${GOARCH}" "${output_dir}"
    
    # Show file size
    binary_name="xmlui-mcp"
    if [ "${GOOS}" = "windows" ]; then
        binary_name="${binary_name}.exe"
    fi
    
    if command -v du >/dev/null 2>&1; then
        size=$(du -h "${output_dir}/${binary_name}" | cut -f1)
        echo "   📏 Size: ${size}"
    fi
    echo ""
done

echo "🎉 Cross-platform build complete!"
echo "   📁 Binaries created in: ${DIST_DIR}/"