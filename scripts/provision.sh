#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/.env"

SNAPSHOT_ID=$(bash "$SCRIPT_DIR/_latest-snapshot.sh" "$SNAPSHOT_LABEL" 2>/dev/null || true)

if [[ -n "$SNAPSHOT_ID" ]]; then
    echo "[provision] Found snapshot $SNAPSHOT_ID — restoring..."
    bash "$SCRIPT_DIR/restore.sh" "$SNAPSHOT_ID"
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

    # Write inventory for Ansible
    cat > "$ROOT_DIR/inventory/hosts.ini" <<EOF
[dev_server]
$SERVER_NAME ansible_host=$SERVER_IP ansible_user=root

[dev_server:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

    # Wait for SSH as root
    bash "$SCRIPT_DIR/_wait-for-ssh.sh" root "$SERVER_IP"

    # Run full Ansible bootstrap
    bash "$SCRIPT_DIR/bootstrap.sh"

    # Update ~/.ssh/config
    bash "$SCRIPT_DIR/_update-ssh-config.sh" hetzner-dev "$SERVER_IP" sinder "$SSH_IDENTITY_FILE"

    echo "[provision] Done. Connect with: ssh hetzner-dev"
fi
