# Seafile Docker with HTTPS

This repository contains a Docker Compose setup for Seafile with:
- **Automatic Let's Encrypt certificates by default**: Caddy obtains and renews trusted certificates for a public hostname.
- **Optional self-signed mode**: You can still run the stack with locally generated certificates when public ACME validation is not possible.
- **Static assets fix**: Startup script to ensure CSS/JS load correctly on Linux/Ubuntu.

## Prerequisites
- Docker and Docker Compose installed.
- For Let's Encrypt mode: `SEAFILE_SERVER_HOSTNAME` must resolve publicly to this machine, and inbound ports `80` and `443` must be reachable from the internet.

## Setup Instructions

### 1. Clone and Configure
Copy `.env.example` to `.env` (if not already present) and update the following variables:

- **`SEAFILE_SERVER_HOSTNAME`**: Set this to the hostname or IP you will use in the browser, without `http://` or `https://`. Example: `acostanet.ddns.net`.
- **`SEAFILE_ADMIN_PASSWORD`**: Change to a strong password.
- **`DB_ROOT_PASSWORD`**: Change this database password.

### 2. Start With Let's Encrypt
For the default mode with automatically renewed public certificates:
```bash
cp .env.example .env
docker compose up -d
```

Wait about 1-2 minutes for the initial setup and certificate issuance to complete, then visit `https://<YOUR_DOMAIN>`.

### 3. Start With Self-Signed Certificates
If your host is not publicly reachable or you want a local fallback, generate a self-signed certificate and start the override stack:
```bash
chmod +x generate_certs.sh
./generate_certs.sh
docker compose -f docker-compose.yml -f docker-compose.selfsigned.yml up -d
```

If you prefer, you can pass the hostname or IP explicitly when generating the self-signed certificate:
```bash
./generate_certs.sh 192.168.1.50
```

### 4. Access Seafile
Go to `https://<YOUR_IP_OR_DOMAIN>`.
- In self-signed mode, accept the browser warning for the local certificate.
- Login with the admin email and password from your `.env` file.

Caddy owns host ports `80` and `443`. The Seafile container is only reachable on the internal Docker network.

## Mode Selection

- **Let's Encrypt**: `docker compose up -d`
- **Self-signed**: `docker compose -f docker-compose.yml -f docker-compose.selfsigned.yml up -d`

## Troubleshooting

### Let's Encrypt certificate was not issued
Check that:
1. `SEAFILE_SERVER_HOSTNAME` points to your public IP.
2. Ports `80` and `443` are forwarded to this host.
3. Your ISP or router is not blocking inbound HTTP/HTTPS.

Inspect the proxy logs with:
```bash
docker logs -f seafile-caddy
```

### "Forbidden (403) CSRF verification failed"
If you changed your hostname/IP *after* the first run:
1. Stop the containers: `docker compose down`
2. Delete the old settings file to force regeneration: `rm seafile-data/seafile/conf/seahub_settings.py`
3. Restart with your chosen mode.

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
