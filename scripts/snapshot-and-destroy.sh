#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/.env"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H%M%SZ")
DESCRIPTION="${SNAPSHOT_LABEL}-${TIMESTAMP}"

echo "[snapshot-and-destroy] Creating snapshot '$DESCRIPTION' from '$SERVER_NAME'..."
hcloud server create-image \
    --type snapshot \
    --description "$DESCRIPTION" \
    "$SERVER_NAME"

echo "[snapshot-and-destroy] Snapshot created. Deleting server '$SERVER_NAME'..."
hcloud server delete "$SERVER_NAME"

echo "[snapshot-and-destroy] Server deleted."

# Delete old snapshots, keep only the 2 most recent
OLD_SNAPSHOTS=$(hcloud image list \
    --type snapshot \
    -o json \
  | python3 -c "
import sys, json
imgs = json.load(sys.stdin)
matching = sorted(
    [i for i in imgs if '$SNAPSHOT_LABEL' in (i.get('description') or '')],
    key=lambda x: x['created'],
    reverse=True
)
for i in matching[2:]:
    print(i['id'])
")

for ID in $OLD_SNAPSHOTS; do
    echo "[snapshot-and-destroy] Deleting old snapshot $ID..."
    hcloud image delete "$ID"
done

echo "[snapshot-and-destroy] Done. Resume with: scripts/provision.sh"
