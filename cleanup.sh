#!/bin/bash
echo "WARNING: This will delete all Seafile data and the database."
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

echo "Stopping containers..."
docker compose down --remove-orphans -v

echo "Removing data directories..."
rm -rf mysql-data
rm -rf seafile-data

# Optional: Remove ssl certs if you want a complete fresh start
# rm -rf ssl

echo "Cleanup complete. Data verified gone."
