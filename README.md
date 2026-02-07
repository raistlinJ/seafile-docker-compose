# Seafile Docker with HTTPS (Self-Signed)

This repository contains a complete Docker Compose setup for Seafile, pre-configured with:
- **HTTPS Trust**: Automated certificate generation and CSRF configuration.
- **Static Assets Fix**: Automated startup script to ensure CSS/JS load correctly on Linux/Ubuntu.
- **Nginx Proxy**: Handles SSL termination.

## Prerequisites
- Docker and Docker Compose installed.

## Setup Instructions

### 1. Clone and Configure
Copy `.env.example` to `.env` (if not already present) and update the following variables:

- **`SEAFILE_SERVER_HOSTNAME`**: Set this to your server's IP address (e.g., `192.168.1.50`) or domain name. **Crucial for trusted access.**
- **`SEAFILE_ADMIN_PASSWORD`**: Change to a strong password.
- **`DB_ROOT_PASSWORD`** & **`DB_PASSWORD`**: Change these database, passwords.

### 2. Generate SSL Certificates
Run the helper script to generate self-signed certificates:
```bash
chmod +x generate_certs.sh
./generate_certs.sh
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
