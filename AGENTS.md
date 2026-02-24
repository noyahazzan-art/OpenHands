# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

OpenHands is an AI coding assistant with a Python/FastAPI backend (port 3000) and React/TypeScript frontend (port 3001). See `Makefile` for all standard dev commands (`make build`, `make run`, `make lint`, `make test`, etc.).

### Key services

| Service | Port | Command |
|---------|------|---------|
| Backend (FastAPI/Uvicorn) | 3000 | `make start-backend` |
| Frontend (Vite/React Router) | 3001 | `make start-frontend` |

### Non-obvious caveats

- **Frontend build required before backend start**: The backend mounts `./frontend/build` as static files. Run `cd frontend && npm run build` before starting the backend, or the backend will crash with `RuntimeError: Directory './frontend/build' does not exist`.
- **Backend startup delay**: The backend takes ~15 seconds to start due to Alembic migrations and MCP server initialization. Wait for the `Uvicorn running on ...` log line before sending requests.
- **Docker required at runtime**: The backend needs Docker to create sandbox containers for agent code execution. Without Docker, the app loads but conversations will fail when trying to spawn a runtime. Docker must be configured with `fuse-overlayfs` storage driver and `iptables-legacy` in nested container environments.
- **LLM API key needed for conversations**: An LLM provider API key must be configured (via the UI settings modal or `config.toml`) for the agent to function. Without it, the UI loads but conversations show "Error occurred".
- **config.toml**: Run `make setup-config-basic` for a minimal config or `make setup-config` for interactive setup. The file is gitignored.
- **Pre-commit hooks**: After `poetry install`, run `git config --unset-all core.hooksPath` then `poetry run pre-commit install --config ./dev_config/python/.pre-commit-config.yaml`.

### Lint / Test / Build

- **Backend lint**: `poetry run pre-commit run --all-files --show-diff-on-failure --config ./dev_config/python/.pre-commit-config.yaml`
- **Frontend lint**: `cd frontend && npm run lint`
- **Frontend unit tests**: `cd frontend && npm run test`
- **Python unit tests**: `poetry run pytest tests/unit -x --timeout=60`
- **Frontend build**: `cd frontend && npm run build`
