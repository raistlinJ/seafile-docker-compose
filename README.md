# Seafile Docker with HTTPS (Self-Signed)

This repository contains a Docker Compose setup for Seafile with:
- **HTTPS on ports 80/443**: Nginx redirects HTTP to HTTPS and terminates TLS.
- **Host-aware self-signed certificates**: The helper script generates a certificate for your configured hostname or IP.
- **Static assets fix**: Startup script to ensure CSS/JS load correctly on Linux/Ubuntu.

## Prerequisites
- Docker and Docker Compose installed.

## Setup Instructions

### 1. Clone and Configure
Copy `.env.example` to `.env` (if not already present) and update the following variables:

- **`SEAFILE_SERVER_HOSTNAME`**: Set this to the hostname or IP you will use in the browser, without `http://` or `https://`. Example: `acostanet.ddns.net`.
- **`SEAFILE_ADMIN_PASSWORD`**: Change to a strong password.
- **`DB_ROOT_PASSWORD`**: Change this database password.

### 2. Generate SSL Certificates
Run the helper script after setting `SEAFILE_SERVER_HOSTNAME`:
```bash
cp .env.example .env
chmod +x generate_certs.sh
./generate_certs.sh
```

If you prefer, you can pass the hostname or IP explicitly:
```bash
./generate_certs.sh 192.168.1.50
```

### 3. Start the Server
```bash
docker-compose up -d
```
Wait about 1-2 minutes for the initial setup to complete. 

### 4. Access Seafile
Go to `https://<YOUR_IP_OR_DOMAIN>`.
- Accept the self-signed certificate warning.
- Login with the admin email and password from your `.env` file.

Nginx now owns host ports `80` and `443`. The Seafile container is only reachable on the internal Docker network.

## Troubleshooting

### "Forbidden (403) CSRF verification failed"
If you changed your hostname/IP *after* the first run:
1. Stop the container: `docker-compose down`
2. Delete the old settings file to force regeneration: `rm seafile-data/seafile/conf/seahub_settings.py`
3. Restart: `docker-compose up -d`

### 502 Bad Gateway
Seafile takes time to start. Wait a minute and check logs:
```bash
docker logs -f seafile
```
Look for "Seahub is started".

### Resetting Data
To wipe everything and start fresh:
```bash
./cleanup.sh
```
**Warning:** This deletes all data!
