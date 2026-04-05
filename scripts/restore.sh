#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/.env"

# Get the latest snapshot by description
SNAPSHOT_ID=$(hcloud image list \
    --type snapshot \
    -o json \
  | python3 -c "
import sys, json
imgs = json.load(sys.stdin)
matching = [i for i in imgs if '$SNAPSHOT_LABEL' in (i.get('description') or '')]
if not matching:
    print('ERROR: No snapshot found matching: $SNAPSHOT_LABEL', file=sys.stderr)
    exit(1)
latest = sorted(matching, key=lambda x: x['created'], reverse=True)[0]
print(latest['id'])
")

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

# Wait for SSH as sinder (snapshot has the user configured)
bash "$SCRIPT_DIR/_wait-for-ssh.sh" sinder "$SERVER_IP"

echo ""
echo "[restore] Done! Update your ~/.ssh/config hetzner-dev HostName to: $SERVER_IP"
echo ""
echo "  Host hetzner-dev"
echo "      HostName $SERVER_IP"
echo "      User sinder"
echo "      IdentityFile ~/.ssh/id_ed25519"
echo ""
echo "Then connect with: ssh hetzner-dev"
