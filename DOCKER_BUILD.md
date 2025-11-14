# Building File Browser from Source with Docker

This document describes how to build the complete File Browser application from source using the provided `Dockerfile.builder`.

## Overview

The `Dockerfile.builder` provides a complete, automated build process that:

1. Builds the Vue.js/TypeScript frontend
2. Compiles the Go backend with embedded frontend assets
3. Creates a minimal, secure runtime image
4. Targets the linux/amd64 platform
5. Uses Alpine Linux as the base

## Quick Start

### Option 1: Using the Build Script (Recommended)

```bash
./build-amd64.sh
```

This is the easiest way to build the image. The script handles all the details and provides helpful feedback.

### Option 2: Direct Docker Build

```bash
docker build -f Dockerfile.builder -t filebrowser:amd64 --platform linux/amd64 .
```

## Build Architecture

The build uses a multi-stage Docker approach with 4 stages:

```
┌─────────────────────────────────────────────────────────────┐
│ Stage 1: Frontend Builder (node:24-alpine)                   │
│ - Installs pnpm 10.22.0                                      │
│ - Builds Vue.js/TypeScript frontend                          │
│ - Outputs: frontend/dist/                                    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 2: Backend Builder (golang:1.25-alpine)                │
│ - Compiles Go backend with CGO disabled                      │
│ - Embeds frontend assets from Stage 1                        │
│ - Static linking for linux/amd64                             │
│ - Outputs: filebrowser binary                                │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 3: Fetcher (alpine:3.22)                               │
│ - Fetches CA certificates                                    │
│ - Downloads tini init system                                 │
│ - Gets JSON.sh script                                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 4: Final Image (busybox:1.37.0-musl)                   │
│ - Minimal runtime environment (~50MB)                        │
│ - Non-root user (UID/GID 1000)                               │
│ - Health check enabled                                       │
│ - Volumes: /srv, /config, /database                          │
│ - Exposes port 80                                            │
└─────────────────────────────────────────────────────────────┘
```

## Files Included

- **Dockerfile.builder** - The multi-stage build Dockerfile
- **build-amd64.sh** - Helper script for building
- **validate-dockerfile.sh** - Validation script to check Dockerfile structure
- **Dockerfile.builder.README.md** - Detailed documentation

## Validation

Before building, you can validate the Dockerfile structure:

```bash
./validate-dockerfile.sh
```

This performs static checks without requiring a Docker build, ensuring:
- All required stages are present
- Alpine Linux base is used
- linux/amd64 architecture is targeted
- Security best practices are followed
- Required files and directories are referenced

## Build Options

### Custom Tag

```bash
./build-amd64.sh --tag myorg/filebrowser:v3.0.0-amd64
```

### No Cache Build

For a clean build without using cached layers:

```bash
./build-amd64.sh --no-cache
```

### BuildKit Support

The build script automatically enables BuildKit for better performance and caching:

```bash
export DOCKER_BUILDKIT=1
```

## Requirements

- Docker 20.10 or later
- 2GB disk space for build layers
- Internet connection (for downloading dependencies)
- ~5-10 minutes for initial build
- ~1-3 minutes for subsequent cached builds

## Running the Built Image

After building:

```bash
docker run -d \
  --name filebrowser \
  -p 8080:80 \
  -v /path/to/files:/srv \
  -v filebrowser_config:/config \
  -v filebrowser_database:/database \
  filebrowser:amd64
```

Access the web interface at `http://localhost:8080`

## Comparison with Other Dockerfiles

| Dockerfile | Purpose | Requires Pre-built Binary |
|------------|---------|---------------------------|
| `Dockerfile` | Runtime only (Alpine) | Yes |
| `Dockerfile.s6` | Runtime with s6-overlay | Yes |
| `Dockerfile.builder` | Complete build + runtime | No |

The `Dockerfile.builder` is unique in that it builds everything from source, making it ideal for:

- Custom builds from modified source code
- CI/CD pipelines that build from source
- Development and testing workflows
- Environments where pre-built binaries aren't available or trusted

## Build Process Details

### Frontend Build

1. Installs Node.js 24 and pnpm 10.22.0
2. Installs dependencies with `pnpm install --frozen-lockfile`
3. Runs TypeScript type checking
4. Builds production assets with Vite
5. Produces optimized, minified output in `frontend/dist/`

### Backend Build

1. Downloads Go dependencies with `go mod download`
2. Embeds frontend assets using Go's `embed` package
3. Compiles with CGO disabled for static linking
4. Targets linux/amd64 architecture explicitly
5. Strips debug symbols with `-s -w` linker flags
6. Injects version information from git

### Security Features

- Non-root user (UID/GID 1000)
- Minimal runtime image based on busybox
- Health check for container orchestration
- CA certificates included for HTTPS
- tini init system for proper signal handling

## Troubleshooting

### Build Fails with Network Errors

Ensure you have internet connectivity and can access:
- registry.npmjs.org (for pnpm/npm packages)
- dl-cdn.alpinelinux.org (for Alpine packages)
- proxy.golang.org (for Go modules)

If behind a corporate firewall, configure Docker to use your proxy.

### Out of Memory During Build

The frontend build can be memory-intensive. Ensure Docker has at least 4GB RAM allocated.

### Build Takes Too Long

Use BuildKit for better caching:
```bash
export DOCKER_BUILDKIT=1
```

On subsequent builds, unchanged layers will be cached.

## Testing

All existing tests pass with the new build configuration:

```bash
go test ./...
```

## License

Apache License 2.0 - Same as the File Browser project

## Support

For issues related to the Docker build process, please open an issue on GitHub with:
- Your Docker version (`docker version`)
- Operating system
- Build logs
- Output of `./validate-dockerfile.sh`
