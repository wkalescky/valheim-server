#!/bin/bash
set -euo pipefail

VALHEIM_CFG="/home/steam/.config/unity3d/IronGate/Valheim"
WORLDS_DIR="${VALHEIM_CFG}/worlds_local"

mkdir -p "${WORLDS_DIR}"

echo "Pulling config from s3://${S3_BUCKET}"

# Source env file if present; otherwise rely on Docker/ECS environment variables
if aws s3 cp "s3://${S3_BUCKET}/config/server.env" /tmp/server.env 2>/dev/null; then
  set -a
  # shellcheck source=/dev/null
  source /tmp/server.env
  set +a
fi

aws s3 cp "s3://${S3_BUCKET}/config/adminlist.txt" "${VALHEIM_CFG}/adminlist.txt"

aws s3 sync "s3://${S3_BUCKET}/worlds/" "${WORLDS_DIR}/"

exec "${STEAMAPPDIR}/start_server.sh"
