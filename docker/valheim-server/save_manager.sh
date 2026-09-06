#!/bin/bash

: "${S3_BUCKET:?S3_BUCKET is required}"
: "${WORLD:?WORLD is required}"

WORLDS_DIR="/home/steam/.config/unity3d/IronGate/Valheim/worlds_local"
S3_PREFIX="s3://${S3_BUCKET}/${WORLD}"
SAVE_INTERVAL=${SAVE_INTERVAL_SECONDS:-300}
BACKUP_INTERVAL=${BACKUP_INTERVAL_SECONDS:-3600}

log() { echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") [save-manager] $*"; }

sync_saves() {
  log "Syncing world saves to S3..."
  aws s3 sync "${WORLDS_DIR}/" "${S3_PREFIX}/" \
    --exclude "*backup_auto*" || log "Save sync failed"
  log "Save sync complete"
}

backup() {
  local timestamp zip_file
  timestamp=$(date -u +"%Y%m%d-%H%M%S")
  zip_file="/tmp/worlds-${timestamp}.zip"
  log "Creating backup ${timestamp}..."
  zip -j "${zip_file}" "${WORLDS_DIR}"/*.db "${WORLDS_DIR}"/*.fwl 2>/dev/null || true
  aws s3 cp "${zip_file}" "${S3_PREFIX}/backups/worlds-${timestamp}.zip" \
    --tagging "backup=true" || log "Backup upload failed"
  rm -f "${zip_file}"
  log "Backup complete"
}

last_backup=$(date +%s)

while true; do
  sleep "${SAVE_INTERVAL}"
  sync_saves
  now=$(date +%s)
  if [ $((now - last_backup)) -ge "${BACKUP_INTERVAL}" ]; then
    backup
    last_backup=${now}
  fi
done
