#!/bin/bash
set -euo pipefail

if [ -f .env ]; then
    set -a
    . ./.env
    set +a
fi

RAW_HOSTNAME_INPUT="${1:-${SEAFILE_SERVER_HOSTNAME:-localhost}}"
HOSTNAME_INPUT="${RAW_HOSTNAME_INPUT#http://}"
HOSTNAME_INPUT="${HOSTNAME_INPUT#https://}"
HOSTNAME_INPUT="${HOSTNAME_INPUT%%/*}"
HOSTNAME_INPUT="${HOSTNAME_INPUT%%:*}"
CERT_DIR="ssl"
KEY_PATH="${CERT_DIR}/server.key"
CERT_PATH="${CERT_DIR}/server.crt"
TMP_CONFIG="$(mktemp)"

cleanup() {
    rm -f "$TMP_CONFIG"
}

trap cleanup EXIT

mkdir -p "$CERT_DIR"

if [ -z "$HOSTNAME_INPUT" ]; then
    echo "Unable to determine a hostname. Set SEAFILE_SERVER_HOSTNAME or pass a hostname/IP as the first argument." >&2
    exit 1
fi

if [[ "$HOSTNAME_INPUT" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    cat > "$TMP_CONFIG" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
x509_extensions = req_ext
distinguished_name = dn

[dn]
CN = ${HOSTNAME_INPUT}

[req_ext]
subjectAltName = @alt_names

[alt_names]
IP.1 = ${HOSTNAME_INPUT}
DNS.1 = localhost
IP.2 = 127.0.0.1
EOF
else
    cat > "$TMP_CONFIG" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
x509_extensions = req_ext
distinguished_name = dn

[dn]
CN = ${HOSTNAME_INPUT}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${HOSTNAME_INPUT}
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF
fi

openssl req -x509 -nodes -days 825 -newkey rsa:2048 \
    -keyout "$KEY_PATH" \
    -out "$CERT_PATH" \
    -config "$TMP_CONFIG"

chmod 600 "$KEY_PATH"

echo "Generated self-signed certificate for ${HOSTNAME_INPUT} in ${CERT_DIR}/"
