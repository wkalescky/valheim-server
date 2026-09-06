#!/bin/bash
log() { echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") [valheim] $*"; }

log "Waiting for world bootstrap to complete..."
until [ -f /tmp/bootstrap.ready ]; do sleep 1; done

log "Bootstrap ready, starting server"
if [ -f /tmp/server.env ]; then
  set -a
  # shellcheck source=/dev/null
  source /tmp/server.env
  set +a
fi
exec "${STEAMAPPDIR}/start_server.sh"
