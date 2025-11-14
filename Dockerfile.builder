## Multi-stage Dockerfile to build everything for linux/amd64 using Alpine Linux

## Stage 1: Build frontend
FROM node:24-alpine AS frontend-builder

# Install pnpm directly via npm as corepack may have network issues
RUN npm install -g pnpm@10.22.0

# Set working directory
WORKDIR /app

# Copy frontend package files
COPY frontend/package.json frontend/pnpm-lock.yaml frontend/

# Install frontend dependencies
RUN cd frontend && pnpm install --frozen-lockfile

# Copy frontend source files
COPY frontend/ frontend/

# Build frontend
RUN cd frontend && pnpm run build

## Stage 2: Build backend
FROM golang:1.25-alpine AS backend-builder

# Install build dependencies
RUN apk add --no-cache git make

# Set working directory
WORKDIR /app

# Copy go module files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Copy built frontend from previous stage
COPY --from=frontend-builder /app/frontend/dist /app/frontend/dist

# Build backend binary for linux/amd64
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w -X github.com/filebrowser/filebrowser/v2/version.Version=$(git describe --tags --always --match=v* 2>/dev/null || echo v0) -X github.com/filebrowser/filebrowser/v2/version.CommitSHA=$(git rev-parse HEAD 2>/dev/null || echo unknown)" \
    -o filebrowser \
    .

## Stage 3: Fetch runtime dependencies
FROM alpine:3.22 AS fetcher

# Install and copy ca-certificates, mailcap, and tini-static; download JSON.sh
RUN apk update && \
    apk --no-cache add ca-certificates mailcap tini-static && \
    wget -O /JSON.sh https://raw.githubusercontent.com/dominictarr/JSON.sh/0d5e5c77365f63809bf6e77ef44a1f34b0e05840/JSON.sh

## Stage 4: Final runtime image
FROM busybox:1.37.0-musl

# Define non-root user UID and GID
ENV UID=1000
ENV GID=1000

# Create user group and user
RUN addgroup -g $GID user && \
    adduser -D -u $UID -G user user

# Copy binary from backend builder
COPY --chown=user:user --from=backend-builder /app/filebrowser /bin/filebrowser

# Copy scripts and configurations into image with proper ownership
COPY --chown=user:user docker/common/ /
COPY --chown=user:user docker/alpine/ /
COPY --chown=user:user --from=fetcher /sbin/tini-static /bin/tini
COPY --from=fetcher /JSON.sh /JSON.sh
COPY --from=fetcher /etc/ca-certificates.conf /etc/ca-certificates.conf
COPY --from=fetcher /etc/ca-certificates /etc/ca-certificates
COPY --from=fetcher /etc/mime.types /etc/mime.types
COPY --from=fetcher /etc/ssl /etc/ssl

# Create data directories, set ownership, and ensure healthcheck script is executable
RUN mkdir -p /config /database /srv && \
    chown -R user:user /config /database /srv \
    && chmod +x /healthcheck.sh

# Define healthcheck script
HEALTHCHECK --start-period=2s --interval=5s --timeout=3s CMD /healthcheck.sh

# Set the user, volumes and exposed ports
USER user

VOLUME /srv /config /database

EXPOSE 80

ENTRYPOINT [ "tini", "--", "/init.sh" ]
