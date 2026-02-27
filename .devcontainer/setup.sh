#!/bin/bash
set -e

# Skip Playwright in initial setup to speed up (run "poetry run playwright install chromium" later if needed)
export INSTALL_PLAYWRIGHT=false

# Mark the current repository as safe for Git to prevent "dubious ownership" errors,
# which can occur in containerized environments when directory ownership doesn't match the current user.
git config --global --add safe.directory "$(realpath .)"

# Use in-project .venv so IDE/extension can find it (avoids "stubPath is not a valid directory")
poetry config virtualenvs.in-project true

# Install `nc`
sudo apt update && sudo apt install netcat -y

# Install `uv` and `uvx`
wget -qO- https://astral.sh/uv/install.sh | sh

# Do common setup tasks (includes poetry install via make install-pre-commit-hooks)
source .openhands/setup.sh
