#!/bin/bash
set -euo pipefail

# Upstream Linux architectures for zellij (https://github.com/zellij-org/zellij):
#   amd64  -> zellij-x86_64-unknown-linux-musl.tar.gz
#   arm64  -> zellij-aarch64-unknown-linux-musl.tar.gz
#
# amd64 and arm64 only. Release assets are not version-stamped in the
# filename, and upstream tags are v-prefixed (e.g. v0.44.3) while this
# script's version argument is not (e.g. 0.44.3).

zellij_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$zellij_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <zellij_version> <build_version> [architecture]"
    echo "Example: $0 0.44.3 1 arm64"
    echo "Example: $0 0.44.3 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, all"
    exit 1
fi

# Function to map Debian architecture to zellij release name
get_zellij_release() {
    local arch=$1
    case "$arch" in
        "amd64")
            echo "zellij-x86_64-unknown-linux-musl"
            ;;
        "arm64")
            echo "zellij-aarch64-unknown-linux-musl"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local zellij_release

    zellij_release=$(get_zellij_release "$build_arch")
    if [ -z "$zellij_release" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64"
        return 1
    fi

    echo "Building for architecture: $build_arch using $zellij_release"

    # Clean up any previous builds
    rm -f zellij || true
    rm -f "${zellij_release}.tar.gz" || true

    # Download and extract zellij binary for this architecture (the tarball
    # contains a single "zellij" binary at its root, no wrapping directory)
    if ! wget "https://github.com/zellij-org/zellij/releases/download/v${zellij_VERSION}/${zellij_release}.tar.gz"; then
        echo "❌ Failed to download zellij binary for $build_arch"
        return 1
    fi

    if ! tar -xf "${zellij_release}.tar.gz"; then
        echo "❌ Failed to extract zellij binary for $build_arch"
        return 1
    fi

    rm -f "${zellij_release}.tar.gz"
    chmod 755 zellij

    # Build packages for all supported Debian distributions
    declare -a arr=("bookworm" "trixie" "forky" "sid")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$zellij_VERSION-${BUILD_VERSION}+${dist}_${build_arch}"
        echo "  Building $FULL_VERSION"

        if ! docker build . -t "zellij-$dist-$build_arch" \
            --build-arg DEBIAN_DIST="$dist" \
            --build-arg zellij_VERSION="$zellij_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "zellij-$dist-$build_arch")"
        if ! docker cp "$id:/zellij_$FULL_VERSION.deb" - > "./zellij_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./zellij_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    # Clean up downloaded binary
    rm -f zellij || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building zellij $zellij_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    ARCHITECTURES=("amd64" "arm64")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la zellij_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
