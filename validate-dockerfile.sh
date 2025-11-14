#!/bin/bash
# Validation script for Dockerfile.builder
# This script performs static checks on the Dockerfile without building it

set -e

DOCKERFILE="Dockerfile.builder"
EXIT_CODE=0

echo "=========================================="
echo "Validating $DOCKERFILE"
echo "=========================================="
echo ""

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
    echo "✗ Error: $DOCKERFILE not found"
    exit 1
fi

echo "✓ Dockerfile exists"

# Check for required stages
STAGES=("frontend-builder" "backend-builder" "fetcher")
for stage in "${STAGES[@]}"; do
    if grep -q "FROM.*AS $stage" "$DOCKERFILE"; then
        echo "✓ Stage '$stage' found"
    else
        echo "✗ Error: Stage '$stage' not found"
        EXIT_CODE=1
    fi
done

# Check for required commands
COMMANDS=("WORKDIR" "COPY" "RUN" "EXPOSE" "ENTRYPOINT")
for cmd in "${COMMANDS[@]}"; do
    if grep -q "^$cmd" "$DOCKERFILE"; then
        echo "✓ Command '$cmd' used"
    else
        echo "⚠ Warning: Command '$cmd' not found"
    fi
done

# Check if it uses Alpine Linux
if grep -q "alpine" "$DOCKERFILE"; then
    echo "✓ Uses Alpine Linux base"
else
    echo "✗ Error: Does not use Alpine Linux base"
    EXIT_CODE=1
fi

# Check for linux/amd64 target
if grep -q "GOARCH=amd64" "$DOCKERFILE"; then
    echo "✓ Targets linux/amd64 architecture"
else
    echo "⚠ Warning: amd64 architecture not explicitly set"
fi

# Check for security best practices
if grep -q "USER" "$DOCKERFILE"; then
    echo "✓ Sets non-root user"
else
    echo "⚠ Warning: Does not set non-root user"
fi

if grep -q "HEALTHCHECK" "$DOCKERFILE"; then
    echo "✓ Includes health check"
else
    echo "⚠ Warning: No health check defined"
fi

# Check for required files
REQUIRED_FILES=("docker/common/" "docker/alpine/" "go.mod" "go.sum")
for file in "${REQUIRED_FILES[@]}"; do
    if grep -q "$file" "$DOCKERFILE"; then
        echo "✓ References required file/directory: $file"
    else
        echo "✗ Error: Missing reference to: $file"
        EXIT_CODE=1
    fi
done

# Check for frontend build
if grep -q "pnpm" "$DOCKERFILE"; then
    echo "✓ Builds frontend with pnpm"
else
    echo "✗ Error: Frontend build not found"
    EXIT_CODE=1
fi

# Check for backend build
if grep -q "go build" "$DOCKERFILE"; then
    echo "✓ Builds backend with Go"
else
    echo "✗ Error: Backend build not found"
    EXIT_CODE=1
fi

# Check for multi-stage optimization
STAGE_COUNT=$(grep -c "^FROM" "$DOCKERFILE")
if [ "$STAGE_COUNT" -ge 3 ]; then
    echo "✓ Uses multi-stage build ($STAGE_COUNT stages)"
else
    echo "⚠ Warning: Only $STAGE_COUNT stages found"
fi

# Check file permissions
if [ -f "build-amd64.sh" ]; then
    if [ -x "build-amd64.sh" ]; then
        echo "✓ build-amd64.sh is executable"
    else
        echo "⚠ Warning: build-amd64.sh is not executable"
    fi
else
    echo "⚠ Warning: build-amd64.sh not found"
fi

# Check documentation
if [ -f "Dockerfile.builder.README.md" ]; then
    echo "✓ Documentation exists"
else
    echo "⚠ Warning: Documentation not found"
fi

echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Validation passed!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Build the image: ./build-amd64.sh"
    echo "  2. Test the image: docker run -d -p 8080:80 filebrowser:amd64"
    echo "  3. Access the UI: http://localhost:8080"
else
    echo "✗ Validation failed!"
    echo "=========================================="
    echo "Please fix the errors above before building"
fi

exit $EXIT_CODE
