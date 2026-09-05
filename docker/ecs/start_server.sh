#!/bin/bash
export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970

echo "Starting server PRESS CTRL-C to exit"

./valheim_server.x86_64 \
  -name "${SERVER_NAME:-My server}" \
  -port "${SERVER_PORT:-2456}" \
  -world "${SERVER_WORLD:-Dedicated}" \
  -password "${SERVER_PASSWORD:?SERVER_PASSWORD is required}" \
  -public "${SERVER_PUBLIC:-0}"

export LD_LIBRARY_PATH=$templdpath
