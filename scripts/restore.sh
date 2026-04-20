#!/usr/bin/env bash
# Usage: restore.sh [snapshot_id]
# If snapshot_id is omitted, looks up the latest one.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/.env"

SNAPSHOT_ID="${1:-}"
if [[ -z "$SNAPSHOT_ID" ]]; then
    SNAPSHOT_ID=$(bash "$SCRIPT_DIR/_latest-snapshot.sh" "$SNAPSHOT_LABEL")
fi

echo "[restore] Creating server '$SERVER_NAME' from snapshot $SNAPSHOT_ID..."
hcloud server create \
    --name "$SERVER_NAME" \
    --type "$SERVER_TYPE" \
    --image "$SNAPSHOT_ID" \
    --location "$LOCATION" \
    --ssh-key "$SSH_KEY_NAME"

SERVER_IP=$(hcloud server ip "$SERVER_NAME")
echo "[restore] Server IP: $SERVER_IP"

# Clear any stale known_hosts entry
ssh-keygen -R "$SERVER_IP" 2>/dev/null || true

# Update ~/.ssh/config before waiting so the wait loop picks up the right identity
bash "$SCRIPT_DIR/_update-ssh-config.sh" hetzner-dev "$SERVER_IP" sinder "$SSH_IDENTITY_FILE"

# Wait for SSH as sinder (snapshot already has the user configured)
bash "$SCRIPT_DIR/_wait-for-ssh.sh" sinder "$SERVER_IP" "$SSH_IDENTITY_FILE"

echo "[restore] Done. Connect with: ssh hetzner-dev"
