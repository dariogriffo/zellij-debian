#!/bin/bash
set -euo pipefail

# Upstream Linux architectures for zellij (https://github.com/zellij-org/zellij):
#   amd64  -> zellij-x86_64-unknown-linux-musl.tar.gz
#   arm64  -> zellij-aarch64-unknown-linux-musl.tar.gz
#
# amd64 and arm64 only.
# TODO: implement zellij build

zellij_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$zellij_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <zellij_version> <build_version> [architecture]"
    echo "Example: $0 1.2.3 1 arm64"
    echo "Example: $0 1.2.3 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, all"
    exit 1
fi

echo "build_ubuntu.sh for zellij is not implemented yet."
exit 1
