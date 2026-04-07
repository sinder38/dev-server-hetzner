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
    IdentityFile $IDENTITY
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null"

if grep -q "^Host $ALIAS$" "$SSH_CONFIG" 2>/dev/null; then
    # Replace the entire existing block using Python
    python3 - "$SSH_CONFIG" "$ALIAS" "$BLOCK" <<'EOF'
import sys, re

path, alias, block = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path).read()

# Match the Host block and everything until the next Host line or end of file
pattern = re.compile(
    r'^Host ' + re.escape(alias) + r'\s*\n(?:[ \t]+\S.*\n)*',
    re.MULTILINE
)
new_text = pattern.sub(block + '\n', text)
open(path, 'w').write(new_text)
EOF
    echo "[ssh-config] Updated '$ALIAS' block to $IP"
else
    # Append new block
    printf '\n%s\n' "$BLOCK" >> "$SSH_CONFIG"
    echo "[ssh-config] Added '$ALIAS' block to ~/.ssh/config"
fi
