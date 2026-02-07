#!/bin/bash
set -e

# Run the original entrypoint logic (if needed) or just the fix + main command
# Seafile's default entrypoint is usually /sbin/my_init or similar. 
# We need to run the fix BEFORE the main process starts or in parallel.

echo "Running static asset fix..."
# Wait for the directory to be created by the main process (which runs in background or via supervisor)
# However, since we are wrapping the entrypoint, we can try to copy immediately if the source exists.

SOURCE_DIR="/opt/seafile/seafile-server-latest/seahub/media"
DEST_DIR="/shared/seafile/seafile-server-latest/seahub"

# We need to wait for seafile to verify/create structure
# The official image uses /sbin/my_init. We can't easily wrap it without blocking.
# So we'll run the fix in the background.

(
    echo "Waiting for Seafile to initialize..."
    for i in {1..60}; do
        if [ -d "$SOURCE_DIR" ]; then
            echo "Source directory found. Copying static assets..."
            tar -cf - -C /opt/seafile/seafile-server-latest/seahub media | tar -xf - -C "$DEST_DIR"
            echo "Static assets copied successfully."
            
            # CSRF / URL Fix
            CONFIG_FILE="/shared/seafile/conf/seahub_settings.py"
            if [ -f "$CONFIG_FILE" ]; then
                if ! grep -q "CSRF_TRUSTED_ORIGINS" "$CONFIG_FILE"; then
                    echo "Injecting CSRF settings into seahub_settings.py..."
                    echo "" >> "$CONFIG_FILE"
                    
                    # Use provided hostname or default to localhost
                    HOSTNAME="${SEAFILE_SERVER_HOSTNAME:-localhost}"
                    
                    echo "CSRF_TRUSTED_ORIGINS = [\"https://${HOSTNAME}\", \"https://${HOSTNAME}:8443\", \"https://localhost\", \"https://127.0.0.1\", \"https://localhost:8443\"]" >> "$CONFIG_FILE"
                    echo "SERVICE_URL = \"https://${HOSTNAME}\"" >> "$CONFIG_FILE"
                    echo "FILE_SERVER_ROOT = \"https://${HOSTNAME}/seafhttp\"" >> "$CONFIG_FILE"
                    
                    echo "Settings injected for ${HOSTNAME}. Please restart container if changes don't take effect immediately."
                    # Do not restart proactively to avoid race conditions with startup script
                fi
            fi
            break
        fi
        echo "Waiting for source directory... ($i/60)"
        sleep 2
    done
) &

# No need to exec my_init manually since this runs inside my_init.d
