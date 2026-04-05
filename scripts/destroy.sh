#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/.env"

read -rp "Destroy server '$SERVER_NAME' WITHOUT taking a snapshot? [y/N] " confirm
[[ "$confirm" == "y" ]] || { echo "Aborted."; exit 0; }

hcloud server delete "$SERVER_NAME"
echo "[destroy] Server '$SERVER_NAME' deleted."
