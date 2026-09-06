#!/bin/bash
set -uo pipefail

: "${S3_BUCKET:?S3_BUCKET is required}"
: "${WORLD:?WORLD is required}"

WORLDS_DIR="/home/steam/.config/unity3d/IronGate/Valheim/worlds_local"
S3_PREFIX="s3://${S3_BUCKET}/${WORLD}"
IDLE_THRESHOLD=${IDLE_THRESHOLD_MINUTES:-10}
IDLE_DATAGRAM_WINDOW=${IDLE_DATAGRAM_WINDOW:-3}
IDLE_DATAGRAM_MAX_COUNT=${IDLE_DATAGRAM_MAX_COUNT:-30}
idle=0

log() { echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") [watchdog] $*"; }

sync_saves() {
  log "Syncing world saves to S3..."
  aws s3 sync "${WORLDS_DIR}/" "${S3_PREFIX}/" \
    --exclude "*backup_auto*" || log "Save sync failed"
  log "Save sync complete"
}

is_server_active() {
  nstat -n > /dev/null 2>&1
  sleep "${IDLE_DATAGRAM_WINDOW}"
  local count
  count=$(nstat | awk '/UdpInDatagrams/{print $2}')
  [ "${count:-0}" -gt "${IDLE_DATAGRAM_MAX_COUNT}" ]
}

log "Starting — idle threshold: ${IDLE_THRESHOLD} minutes, datagram window: ${IDLE_DATAGRAM_WINDOW}s, max count: ${IDLE_DATAGRAM_MAX_COUNT}"

while true; do
  sleep 10
  if is_server_active; then
    [ "${idle}" -gt 0 ] && log "Server active, resetting idle timer"
    idle=0
  else
    idle=$((idle + 1))
    log "No activity detected — idle ${idle}/${IDLE_THRESHOLD} minutes"
    if [ "${idle}" -ge "${IDLE_THRESHOLD}" ]; then
      log "Idle threshold reached, stopping server"
      supervisorctl stop valheim
      break
    fi
  fi
done

log "Valheim stopped; syncing saves..."
sync_saves
log "Shutting down"
supervisorctl shutdown
