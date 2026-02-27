#!/bin/bash
# Switch to Quick Dev Container (no setup - opens in ~1 min instead of 5-30 min)
# Use when "Cursor is setting up..." is stuck for hours.
# Run from project root.

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DC="$ROOT/.devcontainer"
MAIN="$DC/devcontainer.json"
QUICK="$DC/devcontainer-quick.json"
BAK="$DC/devcontainer.json.full-backup"

[ -f "$QUICK" ] || { echo "Error: devcontainer-quick.json not found."; exit 1; }
[ -f "$MAIN" ] && { cp "$MAIN" "$BAK"; echo "Backed up devcontainer.json to devcontainer.json.full-backup"; }
cp "$QUICK" "$MAIN"
echo "Switched to Quick Dev Container (no postCreateCommand)."
echo "Now: Close Cursor, then Reopen in Container. It will open fast."
echo "After it opens, run: poetry config virtualenvs.in-project true && poetry install"
