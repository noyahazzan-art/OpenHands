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

### Local GPU deployment (Proxmox + Windows VM)

A production-ready local deployment runs on the user's Proxmox server:

| Component | Location | Details |
|-----------|----------|---------|
| OpenHands | Proxmox (`10.0.0.100:3000`) | Docker container, `ghcr.io/openhands/openhands:main` |
| Ollama + GPU | Windows VM (`10.0.0.6:11434`) | RTX 4080 SUPER, `qwen2.5:14b` (14.8B params, 9GB VRAM) |
| NinjaTrader 8 | Windows VM (`10.0.0.6`) | Strategies: `C:\Users\nchma\Documents\NinjaTrader 8\bin\Custom\Strategies` |
| SSH access | `nchma@10.0.0.6:22` | cmd.exe default shell, sshpass available |
| Tailscale | `100.83.60.32` (Proxmox) | For remote access |

**Proxmox OpenHands setup:** `/opt/openhands/docker-compose.yml` with `network_mode: host` and `privileged: true`.

**Ollama on Windows:** Started via `C:\start_ollama.bat` which sets `OLLAMA_HOST=0.0.0.0`. Proxmox has a systemd service `ollama-forward` (socat on port 11434) forwarding to Windows.

**`security_risk` fix:** The `security_risk` parameter was made optional in all 5 tool definitions (bash, ipython, str_replace_editor, llm_based_edit, browser) to support local models that don't produce this field.

### Proxmox runtime patches

The Proxmox kernel's AppArmor policy blocks `socket.socketpair()` and Unix socket creation in unprivileged Docker containers. The following patches are applied via custom Docker images:

**App image (`openhands-app-patched`):**
- Injects `security_opt=["apparmor=unconfined", "seccomp=unconfined"]` into sandbox container creation at `docker_runtime.py` line 548.

**Runtime image (`openhands-runtime-patched`):**
- `async_utils.py`: `GENERAL_TIMEOUT` increased from 15 to 300 seconds.
- `selector_events.py`: Replaced `socket.socketpair()` with TCP localhost connection for event loop self-pipe (works without AppArmor exceptions).
- `plugins/jupyter/__init__.py`: Replaced with no-op stub (Jupyter kernel startup hangs in restricted Docker).
- `plugins/vscode/__init__.py`: Replaced with no-op stub (VSCode server startup hangs in restricted Docker).
- `INIT_PLUGIN_TIMEOUT` env var set to 300.

Build commands on Proxmox:
```bash
cd /opt/openhands/runtime-patch
docker build -t openhands-runtime-patched:latest .
docker build -t openhands-app-patched:latest /opt/openhands/app-patch/
```

Systemd services on Proxmox:
- `ollama-forward.service`: socat forwarding port 11434 to Windows VM (10.0.0.6:11434)
- `openhands-redirect.service`: socat forwarding port 3001 to localhost:3000

### Current LLM Configuration

**Primary (DeepSeek API):** `deepseek/deepseek-chat` via `https://api.deepseek.com`
- Hebrew: excellent, Tool calling: excellent, Speed: 2-5s, Cost: ~$2/month

**Fallback (Local GPU):** `ollama/qwen3:14b` via `http://10.0.0.6:11434`
- Hebrew: good, Tool calling: good, Speed: 5-20s, Cost: free (RTX 4080 SUPER)

To switch: update settings at `http://10.0.0.100:3001` Settings page.
