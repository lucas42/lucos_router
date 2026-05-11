#!/bin/sh
set -e

# Load container environment variables — certbot hooks run in a subprocess
# that may not inherit the container environment (e.g. HOSTDOMAIN, SYSTEM).
# /etc/.env is written by startup.sh from the container's env at boot.
export $(cat /etc/.env | xargs)

curl https://loganne.l42.eu/events -H "User-Agent: $SYSTEM" --data '{
  "type": "certificateRenewed",
  "source": "lucos_router",
  "certificate_domain": "'"$RENEWED_DOMAINS"'",
  "host": "'"$HOSTDOMAIN"'",
  "humanReadable":"Certificate issued for '"$RENEWED_DOMAINS"' on host '"$HOSTDOMAIN"'"
}' -H "Content-Type: application/json" --fail --silent --show-error