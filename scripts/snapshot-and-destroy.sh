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
    "$SERVER_NAME" &

SNAPSHOT_PID=$!

# Wait just in case
sleep 10

# Delete server while snapshot is in progress (it works)
echo "[snapshot-and-destroy] Deleting server '$SERVER_NAME'..."
hcloud server delete "$SERVER_NAME"

wait $SNAPSHOT_PID

echo "[snapshot-and-destroy] Server deleted."

# Delete old snapshots beyond the configured limit
OLD_SNAPSHOTS=$(bash "$SCRIPT_DIR/_latest-snapshot.sh" "$SNAPSHOT_LABEL" --all-but-keep "${SNAPSHOTS_TO_KEEP:-1}" || true)

for ID in $OLD_SNAPSHOTS; do
    # Safety check: only delete if the description still matches our label
    DESC=$(hcloud image describe "$ID" -o json | python3 -c "import sys,json; print(json.load(sys.stdin).get('description',''))")
    if [[ ! "$DESC" =~ ^${SNAPSHOT_LABEL}-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{6}Z$ ]]; then
        echo "[snapshot-and-destroy] SKIP: snapshot $ID description '$DESC' does not match label '$SNAPSHOT_LABEL', refusing to delete."
        continue
    fi
    echo "[snapshot-and-destroy] Deleting old snapshot $ID ('$DESC')..."
    hcloud image delete "$ID"
done

echo "[snapshot-and-destroy] Done. Resume with: scripts/provision.sh"
