#!/bin/bash
set -e

echo "Fixing static assets (CSS/JS/Images) for Ubuntu..."

# Check if container is running
if ! docker ps | grep -q seafile; then
    echo "Error: Seafile container is not running."
    echo "Please start the services first: docker-compose up -d"
    exit 1
fi

# Define destination directory on host
DEST_DIR="./seafile-data/seafile/seafile-server-latest/seahub"

# Verify destination exists
if [ ! -d "$DEST_DIR" ]; then
    echo "Error: Destination directory not found at $DEST_DIR"
    echo "Ensure 'seafile-data' volume is mounted and initialized."
    exit 1
fi

echo "Copying static media files from container to host..."
# Use tar pipe to preserve symlinks and permissions
docker exec seafile tar -cf - -C /opt/seafile/seafile-server-latest/seahub media | tar -xf - -C "$DEST_DIR"

if docker ps --format '{{.Names}}' | grep -qx seafile-caddy; then
    echo "Restarting Caddy to pick up changes..."
    docker restart seafile-caddy
else
    echo "Caddy container is not running. Static assets were copied, but no proxy was restarted."
fi

echo "Success! Static assets restored."
