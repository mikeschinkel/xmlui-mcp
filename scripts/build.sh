#!/usr/bin/env bash

# Build script for xmlui-mcp
# Usage: ./build.sh [GOOS] [GOARCH] [output_dir]
# Examples:
#   ./build.sh                    # Build for current platform to bin/
#   ./build.sh linux amd64       # Build for Linux AMD64 to dist/linux-amd64/
#   ./build.sh darwin arm64      # Build for macOS Apple Silicon to dist/darwin-arm64/

set -e

GOOS=${1:-$(go env GOOS)}
GOARCH=${2:-$(go env GOARCH)}
OUTPUT_DIR=${3:-"bin"}

BINARY_NAME="xmlui-mcp"
if [ "$GOOS" = "windows" ]; then
    BINARY_NAME="${BINARY_NAME}.exe"
fi

# Get build information
VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build flags
LDFLAGS=(-ldflags "-X main.version=${VERSION} -X main.commit=${COMMIT} -X main.buildTime=${BUILD_TIME}")

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Build
echo "Building ${BINARY_NAME} for ${GOOS}/${GOARCH}..."
GOOS=$GOOS GOARCH=$GOARCH go build -trimpath "${LDFLAGS[@]}" -o "${OUTPUT_DIR}/${BINARY_NAME}" .
echo "✓ Built ${OUTPUT_DIR}/${BINARY_NAME}"
