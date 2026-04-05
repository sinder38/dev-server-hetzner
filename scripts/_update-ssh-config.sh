#!/usr/bin/env bash
# Usage: _update-ssh-config.sh <host_alias> <ip> <ssh_user> <identity_file>
# Creates or updates a Host block in ~/.ssh/config.
set -euo pipefail

ALIAS="${1:?}"
IP="${2:?}"
SSH_USER="${3:?}"
IDENTITY="${4:?}"

SSH_CONFIG="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

BLOCK="Host $ALIAS
    HostName $IP
    User $SSH_USER
    IdentityFile $IDENTITY"

if grep -q "^Host $ALIAS$" "$SSH_CONFIG" 2>/dev/null; then
    # Update HostName inside the existing block using Python (handles multi-block files safely)
    python3 - "$SSH_CONFIG" "$ALIAS" "$IP" <<'EOF'
import sys, re

path, alias, ip = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path).read()

# Replace HostName line that follows the matching Host line
pattern = re.compile(
    r'(^Host ' + re.escape(alias) + r'\s*\n(?:[ \t]+\S.*\n)*?[ \t]+HostName[ \t]+)\S+',
    re.MULTILINE
)
new_text = pattern.sub(r'\g<1>' + ip, text)
open(path, 'w').write(new_text)
EOF
    echo "[ssh-config] Updated HostName for '$ALIAS' to $IP"
else
    # Append new block
    printf '\n%s\n' "$BLOCK" >> "$SSH_CONFIG"
    echo "[ssh-config] Added '$ALIAS' block to ~/.ssh/config"
fi
