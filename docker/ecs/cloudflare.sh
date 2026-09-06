#!/bin/bash
set -euo pipefail

log() { echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") [cloudflare] $*"; }

if [ -z "${CF_API_TOKEN:-}" ] || [ -z "${CF_ZONE_ID:-}" ] || [ -z "${CF_DOMAIN:-}" ]; then
  log "Cloudflare vars not set; skipping DNS registration"
  exit 0
fi

CF_RECORD_NAME="${WORLD}.${CF_DOMAIN}"
log "Registering DNS ${CF_RECORD_NAME}..."
PUBLIC_IP=$(curl -sf https://checkip.amazonaws.com)
RECORD_ID=$(curl -sf -X GET \
  "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?type=A&name=${CF_RECORD_NAME}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" | jq -r '.result[0].id // empty')

if [ -n "${RECORD_ID}" ]; then
  curl -sf -X PUT \
    "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"type\":\"A\",\"name\":\"${CF_RECORD_NAME}\",\"content\":\"${PUBLIC_IP}\",\"ttl\":60,\"proxied\":false}" \
    > /dev/null
else
  curl -sf -X POST \
    "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"type\":\"A\",\"name\":\"${CF_RECORD_NAME}\",\"content\":\"${PUBLIC_IP}\",\"ttl\":60,\"proxied\":false}" \
    > /dev/null
fi

log "DNS ${CF_RECORD_NAME} -> ${PUBLIC_IP}"
