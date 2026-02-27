#!/bin/bash
# Restore Full Dev Container (with automatic setup)
# Run from project root.

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DC="$ROOT/.devcontainer"
MAIN="$DC/devcontainer.json"
BAK="$DC/devcontainer.json.full-backup"

if [ ! -f "$BAK" ]; then
    echo "No backup found. The full config uses postCreateCommand: .devcontainer/setup.sh"
    echo "To restore manually, ensure devcontainer.json contains: \"postCreateCommand\": \".devcontainer/setup.sh\""
    exit 0
fi
cp "$BAK" "$MAIN"
rm -f "$BAK"
echo "Restored full Dev Container config."
echo "Rebuild container to run full setup again."
