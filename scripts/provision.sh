#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/.env"

# Find the latest snapshot matching our label
SNAPSHOT_ID=$(hcloud image list \
    --type snapshot \
    -o json \
  | python3 -c "
import sys, json
imgs = json.load(sys.stdin)
matching = [i for i in imgs if '$SNAPSHOT_LABEL' in (i.get('description') or '')]
if not matching:
    exit(1)
latest = sorted(matching, key=lambda x: x['created'], reverse=True)[0]
print(latest['id'])
" 2>/dev/null || true)

if [[ -n "$SNAPSHOT_ID" ]]; then
    echo "[provision] Found snapshot $SNAPSHOT_ID — restoring..."
    bash "$SCRIPT_DIR/restore.sh"
else
    echo "[provision] No snapshot found — creating fresh server..."

    hcloud server create \
        --name "$SERVER_NAME" \
        --type "$SERVER_TYPE" \
        --image "$IMAGE" \
        --location "$LOCATION" \
        --ssh-key "$SSH_KEY_NAME" \
        --user-data-from-file "$ROOT_DIR/cloud-init/initial.yml"

    SERVER_IP=$(hcloud server ip "$SERVER_NAME")
    echo "[provision] Server IP: $SERVER_IP"

    # Write inventory
    cat > "$ROOT_DIR/inventory/hosts.ini" <<EOF
[dev_server]
$SERVER_NAME ansible_host=$SERVER_IP ansible_user=root

[dev_server:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

    # Wait for SSH as root
    bash "$SCRIPT_DIR/_wait-for-ssh.sh" root "$SERVER_IP"

    # Run bootstrap
    bash "$SCRIPT_DIR/bootstrap.sh"

    echo ""
    echo "[provision] Done! Add this to ~/.ssh/config to connect:"
    echo ""
    echo "  Host hetzner-dev"
    echo "      HostName $SERVER_IP"
    echo "      User sinder"
    echo "      IdentityFile ~/.ssh/id_ed25519"
    echo ""
    echo "Then connect with: ssh hetzner-dev"
fi
