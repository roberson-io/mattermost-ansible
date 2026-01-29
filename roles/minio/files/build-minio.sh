#!/bin/bash
# MinIO build script with explicit output handling
# This script builds MinIO from source with real-time output

set -euo pipefail

# Unbuffer output explicitly
exec 1> >(stdbuf -oL cat >&1)
exec 2> >(stdbuf -oL cat >&2)

# Export Go environment
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export GOPROXY=https://proxy.golang.org,direct

BUILD_PATH="$1"
OUTPUT_PATH="$2"

echo "=== MinIO Build Script Started at $(date) ===" >&2
echo "=== Working directory: $BUILD_PATH ===" >&2
echo "=== Output path: $OUTPUT_PATH ===" >&2

cd "$BUILD_PATH"

echo "=== Go version: $(go version) ===" >&2
echo "=== GOPROXY: $GOPROXY ===" >&2
echo "=== GOPATH: $GOPATH ===" >&2

# Test network connectivity to Go proxy
echo "=== Testing network connectivity to proxy.golang.org ===" >&2
if curl -sSf --connect-timeout 10 --max-time 30 https://proxy.golang.org >/dev/null 2>&1; then
    echo "=== Network connectivity: OK ===" >&2
else
    echo "ERROR: Cannot reach https://proxy.golang.org" >&2
    echo "This may indicate network restrictions or firewall issues" >&2
    exit 1
fi

# Download Go modules
echo "=== Downloading Go modules (this may take a few minutes) ===" >&2
if ! go mod download 2>&1; then
    echo "ERROR: Failed to download Go modules" >&2
    exit 1
fi
echo "=== Go modules downloaded successfully at $(date) ===" >&2

# Build MinIO binary
echo "=== Building MinIO binary (this may take 5-10 minutes) ===" >&2
if ! go build -v -o "$OUTPUT_PATH" 2>&1; then
    echo "ERROR: Failed to build MinIO binary" >&2
    exit 1
fi

echo "=== Build completed successfully at $(date) ===" >&2
ls -lh "$OUTPUT_PATH" >&2
echo "=== MinIO binary size: $(du -h "$OUTPUT_PATH" | cut -f1) ===" >&2
