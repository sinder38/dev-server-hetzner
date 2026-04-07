#!/usr/bin/env bash
# Usage: _wait-for-ssh.sh <user> <host> <identity_file>
set -euo pipefail

USER=$1
HOST=$2
IDENTITY=$3

echo "[wait-for-ssh] Waiting for SSH on $USER@$HOST..."
for i in $(seq 1 30); do
    if ssh -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null \
           -o ConnectTimeout=5 \
           -o BatchMode=yes \
           -i "$IDENTITY" \
           "$USER@$HOST" true 2>/dev/null; then
        echo "[wait-for-ssh] SSH is up."
        exit 0
    fi
    echo "[wait-for-ssh] Attempt $i/30 failed, retrying in 10s..."
    sleep 10
done

echo "[wait-for-ssh] ERROR: SSH never became available on $HOST."
exit 1
