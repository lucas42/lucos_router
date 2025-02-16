#!/bin/sh
set -e

curl https://loganne.l42.eu/events --data '{
  "type": "certificateRenewed",
  "source": "lucos_router",
  "certificate_domain": "'"$RENEWED_DOMAINS"'",
  "host": "'"$HOSTDOMAIN"'",
  "humanReadable":"Certificate issued for '"$RENEWED_DOMAINS"' on host '"$HOSTDOMAIN"'"
}' -H "Content-Type: application/json" --fail --silent --show-error