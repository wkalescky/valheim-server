#!/bin/bash
set -euo pipefail

: "${S3_BUCKET:?S3_BUCKET is required}"
: "${WORLD:?WORLD is required}"

VALHEIM_CFG="/home/steam/.config/unity3d/IronGate/Valheim"
WORLDS_DIR="${VALHEIM_CFG}/worlds_local"
S3_PREFIX="s3://${S3_BUCKET}/${WORLD}"

log() { echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"; }

mkdir -p "${WORLDS_DIR}"

if [ -n "${CF_API_TOKEN:-}" ] && [ -n "${CF_ZONE_ID:-}" ] && [ -n "${CF_DOMAIN:-}" ]; then
  CF_RECORD_NAME="${WORLD}.${CF_DOMAIN}"
  log "Registering DNS..."
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
else
  log "Cloudflare vars not set; skipping DNS registration"
fi

log "Loading world '${WORLD}' from ${S3_PREFIX}"

log "Fetching server.env..."
if aws s3 cp "${S3_PREFIX}/server.env" /tmp/server.env 2>/dev/null; then
  log "server.env loaded; sourcing environment overrides"
  set -a
  # shellcheck source=/dev/null
  source /tmp/server.env
  set +a
else
  log "No server.env found; using container environment"
fi

for f in adminlist.txt bannedlist.txt permittedlist.txt; do
  log "Fetching ${f}..."
  if aws s3 cp "s3://${S3_BUCKET}/${f}" "${VALHEIM_CFG}/${f}" 2>/dev/null; then
    log "${f} loaded ($(wc -l < "${VALHEIM_CFG}/${f}") entries)"
  else
    log "No ${f} found in S3; starting with empty file"
    touch "${VALHEIM_CFG}/${f}"
  fi
done

log "Syncing world files from S3..."
aws s3 sync "${S3_PREFIX}/" "${WORLDS_DIR}/" \
  --exclude "server.env" \
  --exclude "adminlist.txt"
log "World sync complete"

log "Starting Valheim server..."
exec "${STEAMAPPDIR}/start_server.sh"
