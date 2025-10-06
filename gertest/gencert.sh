#!/bin/sh
set -e

# This script is intended to run inside an Alpine container
if ! command -v openssl >/dev/null 2>&1; then
  apk add --no-cache openssl >/dev/null
fi

mkdir -p /certs
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -subj "/CN=test.mgt.com" \
  -addext "subjectAltName=DNS:test.mgt.com,DNS:pma.mgt.com" \
  -keyout /certs/selfsigned.key \
  -out /certs/selfsigned.crt
chmod 600 /certs/selfsigned.key
ls -l /certs


