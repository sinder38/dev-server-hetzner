#!/usr/bin/env bash
# Usage:
#   _latest-snapshot.sh <label>
#       Prints the ID of the most recent matching snapshot. Exits 1 if none found.
#
#   _latest-snapshot.sh <label> --all-but-keep <n>
#       Prints IDs of all matching snapshots except the <n> most recent (one per line).
set -euo pipefail

LABEL="${1:?Usage: _latest-snapshot.sh <label> [--all-but-keep <n>]}"
MODE="latest"
KEEP=0

if [[ "${2:-}" == "--all-but-keep" ]]; then
    MODE="all-but-keep"
    KEEP="${3:?--all-but-keep requires a number}"
fi

SCRIPT='
import re, sys, json

label, mode, keep = sys.argv[1], sys.argv[2], int(sys.argv[3])
imgs = json.load(sys.stdin)
pattern = re.compile(r"^" + re.escape(label) + r"-\d{4}-\d{2}-\d{2}T\d{6}Z$")
matching = sorted(
    [i for i in imgs if pattern.match(i.get("description") or "")],
    key=lambda x: x["created"],
    reverse=True
)

if mode == "latest":
    if not matching:
        sys.exit(1)
    print(matching[0]["id"])
elif mode == "all-but-keep":
    for i in matching[keep:]:
        print(i["id"])
'

hcloud image list --type snapshot -o json \
  | python3 -c "$SCRIPT" "$LABEL" "$MODE" "$KEEP"
