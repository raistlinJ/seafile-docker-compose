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
            HOSTNAME="${SEAFILE_SERVER_HOSTNAME:-localhost}"
            
            # Check if seahub_settings.py exists
            if [ -f "$CONFIG_FILE" ]; then
                # Check if the specific hostname is already trusted (or at least mentioned in the config)
                # We grep for the hostname in the file. If not found, we append our config.
                # Appending to the end of a python file overrides previous variable definitions.
                 if ! grep -q "https://${HOSTNAME}" "$CONFIG_FILE"; then
                    echo "Injecting CSRF settings for ${HOSTNAME} into seahub_settings.py..."
                    {
                        echo ""
                        echo "# Added by entrypoint.sh - Overriding/Adding CSRF settings"
                        echo "CSRF_TRUSTED_ORIGINS = [\"https://${HOSTNAME}\", \"https://${HOSTNAME}:8443\", \"https://localhost\", \"https://127.0.0.1\", \"https://127.0.0.1:8443\"]"
                        echo "SERVICE_URL = \"https://${HOSTNAME}\""
                        echo "FILE_SERVER_ROOT = \"https://${HOSTNAME}/seafhttp\""
                    } >> "$CONFIG_FILE"
                    echo "Settings injected for ${HOSTNAME}. Please restart container."
                else
                    echo "Hostname ${HOSTNAME} already found in seahub_settings.py. Skipping injection."
                fi
            fi
            break
        fi
        echo "Waiting for source directory... ($i/60)"
        sleep 2
    done
) &

# No need to exec my_init manually since this runs inside my_init.d
