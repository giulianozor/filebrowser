# Dockerfile.builder - Build Everything for linux/amd64

This Dockerfile provides a complete multi-stage build process to compile the entire File Browser application (frontend + backend) for the linux/amd64 platform using Alpine Linux as the base.

## Features

- **Multi-stage build**: Optimized for minimal final image size
- **Alpine Linux base**: Lightweight and secure base images
- **Complete build process**: Builds both frontend (Vue.js/TypeScript) and backend (Go)
- **Platform-specific**: Targets linux/amd64 architecture
- **Security-focused**: Runs as non-root user, includes health checks

## Build Stages

1. **Stage 1 - Frontend Builder** (`frontend-builder`)
   - Base: `node:24-alpine`
   - Installs pnpm 10.22.0
   - Builds Vue.js frontend with TypeScript
   - Produces optimized production assets in `frontend/dist`

2. **Stage 2 - Backend Builder** (`backend-builder`)
   - Base: `golang:1.25-alpine`
   - Compiles Go backend with embedded frontend assets
   - Creates statically-linked binary for linux/amd64
   - Includes version information from git

3. **Stage 3 - Fetcher** (`fetcher`)
   - Base: `alpine:3.22`
   - Fetches runtime dependencies (certificates, tini, JSON.sh)

4. **Stage 4 - Final Runtime**
   - Base: `busybox:1.37.0-musl`
   - Minimal runtime environment
   - Non-root user execution
   - Health check support

## Usage

### Basic Build

```bash
docker build -f Dockerfile.builder -t filebrowser:amd64 --platform linux/amd64 .
```

### Build with Custom Tag

```bash
docker build -f Dockerfile.builder -t myorg/filebrowser:v3.0.0-amd64 --platform linux/amd64 .
```

### Build with BuildKit Cache

For faster subsequent builds, use BuildKit cache mounts:

```bash
DOCKER_BUILDKIT=1 docker build -f Dockerfile.builder -t filebrowser:amd64 --platform linux/amd64 .
```

### Run the Built Image

```bash
docker run -d \
  -p 8080:80 \
  -v /path/to/files:/srv \
  -v /path/to/config:/config \
  -v /path/to/database:/database \
  filebrowser:amd64
```

## Requirements

- Docker 20.10+ or Docker Engine with BuildKit support
- Internet connection during build (for downloading dependencies)
- Sufficient disk space (~2GB for build layers, ~50MB for final image)

## Environment Variables

The final image supports the same environment variables as the standard File Browser image:

- `UID`: User ID (default: 1000)
- `GID`: Group ID (default: 1000)

## Volumes

- `/srv`: File storage directory
- `/config`: Configuration directory
- `/database`: Database directory

## Exposed Ports

- `80`: Web interface and API

## Build Time

Approximate build times (will vary based on hardware and network):
- First build: 5-10 minutes
- Cached builds: 1-3 minutes

## Troubleshooting

### Network Issues During Build

If you encounter network timeouts during the build, try:

1. Check your internet connection
2. Configure Docker to use a different DNS server
3. Use a corporate proxy if behind a firewall
4. Try building during off-peak hours

### Out of Memory

If the build fails with OOM errors:

1. Increase Docker memory limits
2. Close other applications
3. Build on a machine with more RAM

### Build Cache Issues

To force a clean build:

```bash
docker build --no-cache -f Dockerfile.builder -t filebrowser:amd64 --platform linux/amd64 .
```

## Differences from Dockerfile and Dockerfile.s6

- **Dockerfile**: Runtime-only, requires pre-built binary
- **Dockerfile.s6**: Runtime-only with s6-overlay, requires pre-built binary
- **Dockerfile.builder**: Complete build-from-source + runtime (this file)

## Development

To build only specific stages for testing:

```bash
# Test frontend build
docker build -f Dockerfile.builder --target frontend-builder -t test:frontend .

# Test backend build
docker build -f Dockerfile.builder --target backend-builder -t test:backend .
```

## License

This Dockerfile is part of the File Browser project and follows the same license (Apache License 2.0).
