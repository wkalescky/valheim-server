#!/bin/bash
set -euo pipefail

rm -rf ~/.aws/sso/cache/* ~/.aws/cli/cache/*
aws login
python3 "$(dirname "$0")/aws_login.py" "${1:-/tmp/.aws-valheim-env}"
