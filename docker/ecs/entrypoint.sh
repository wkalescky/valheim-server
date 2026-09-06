#!/bin/bash
set -euo pipefail

: "${S3_BUCKET:?S3_BUCKET is required}"
: "${WORLD:?WORLD is required}"

VALHEIM_CFG="/home/steam/.config/unity3d/IronGate/Valheim"
WORLDS_DIR="${VALHEIM_CFG}/worlds_local"
S3_PREFIX="s3://${S3_BUCKET}/${WORLD}"

log() { echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"; }

mkdir -p "${WORLDS_DIR}"

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
