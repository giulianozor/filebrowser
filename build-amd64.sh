#!/bin/bash
# Build script for File Browser linux/amd64 using Dockerfile.builder
#
# This script builds the complete File Browser application for linux/amd64
# using Alpine Linux as the base.
#
# Usage:
#   ./build-amd64.sh [options]
#
# Options:
#   -t, --tag TAG        Docker image tag (default: filebrowser:amd64)
#   -n, --no-cache       Build without using cache
#   -h, --help           Show this help message
#
# Examples:
#   ./build-amd64.sh
#   ./build-amd64.sh --tag myorg/filebrowser:v3.0.0-amd64
#   ./build-amd64.sh --no-cache

set -e

# Default values
TAG="filebrowser:amd64"
NO_CACHE=""
PLATFORM="linux/amd64"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -t|--tag)
      TAG="$2"
      shift 2
      ;;
    -n|--no-cache)
      NO_CACHE="--no-cache"
      shift
      ;;
    -h|--help)
      echo "Build File Browser for linux/amd64"
      echo ""
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  -t, --tag TAG        Docker image tag (default: filebrowser:amd64)"
      echo "  -n, --no-cache       Build without using cache"
      echo "  -h, --help           Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0"
      echo "  $0 --tag myorg/filebrowser:v3.0.0-amd64"
      echo "  $0 --no-cache"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run '$0 --help' for usage information"
      exit 1
      ;;
  esac
done

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

# Check Docker version
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "0.0.0")
REQUIRED_VERSION="20.10"

if ! printf '%s\n%s\n' "$REQUIRED_VERSION" "$DOCKER_VERSION" | sort -V -C; then
    echo "Warning: Docker version $DOCKER_VERSION is older than recommended $REQUIRED_VERSION"
    echo "Some features may not work correctly"
fi

# Enable BuildKit for better performance
export DOCKER_BUILDKIT=1

echo "=========================================="
echo "Building File Browser for linux/amd64"
echo "=========================================="
echo "Tag:       $TAG"
echo "Platform:  $PLATFORM"
echo "No cache:  ${NO_CACHE:-false}"
echo "=========================================="
echo ""

# Build the image
echo "Starting build process..."
docker build \
    -f Dockerfile.builder \
    --platform "$PLATFORM" \
    -t "$TAG" \
    $NO_CACHE \
    .

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ Build successful!"
    echo "=========================================="
    echo "Image: $TAG"
    echo ""
    echo "To run the container:"
    echo "  docker run -d -p 8080:80 -v /path/to/files:/srv $TAG"
    echo ""
    echo "To inspect the image:"
    echo "  docker images $TAG"
    echo "  docker inspect $TAG"
    exit 0
else
    echo ""
    echo "=========================================="
    echo "✗ Build failed!"
    echo "=========================================="
    echo "Check the error messages above for details"
    exit $BUILD_STATUS
fi
