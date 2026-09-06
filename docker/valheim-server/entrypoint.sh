#!/bin/bash
set -euo pipefail

: "${S3_BUCKET:?S3_BUCKET is required}"
: "${WORLD:?WORLD is required}"

exec supervisord -c /supervisord.conf
