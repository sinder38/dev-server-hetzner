#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "[bootstrap] Installing Ansible Galaxy collections..."
ansible-galaxy collection install -r requirements.yml

echo "[bootstrap] Running bootstrap playbook..."
ansible-playbook playbooks/bootstrap.yml -v

echo "[bootstrap] Done."
