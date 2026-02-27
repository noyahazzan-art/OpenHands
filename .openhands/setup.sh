#! /bin/bash

echo "Setting up the environment..."

# Install pre-commit hooks if .git directory exists (includes poetry install via install-python-dependencies)
if [ -d ".git" ]; then
    echo "Installing pre-commit hooks..."
    make install-pre-commit-hooks
fi
