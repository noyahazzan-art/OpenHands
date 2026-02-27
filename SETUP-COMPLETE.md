# OpenHands - Setup Complete

This document summarizes the development environment setup and known configuration.

## Quick Start

```bash
make setup-all    # One-time: config, workspace, dirs, frontend build
make verify       # Verify setup
make run          # Start backend (3000) + frontend (3001)
make start-backend   # Backend only
make start-frontend  # Frontend only
```

## Environment Status

| Component | Status |
|-----------|--------|
| Python 3.12 | ✅ |
| Node.js 22+ | ✅ |
| Poetry | ✅ |
| config.toml | ✅ (minimal) |
| frontend/build | ✅ |
| workspace/ | ✅ |
| logs/ | ✅ |
| Pre-commit hooks | ✅ |
| npm vulnerabilities | ✅ 0 |

## Configuration

- **config.toml**: Minimal config with `workspace_base`, `[llm]` section for API key
- **LLM API key**: Set in config.toml or via UI Settings modal
- **Workspace**: `./workspace` - agent working directory

## Docker

- **Required for**: Agent conversations (sandbox containers)
- **Status in Dev Container**: Docker may be installed but daemon often cannot run due to:
  - overlay/overlay2 storage driver limitations
  - iptables restrictions in nested containers
  - Missing fuse-overlayfs

**Without Docker**: App loads, UI works, but conversations fail when spawning runtime.

## Tests

```bash
make test              # Full suite
make test-frontend     # Frontend only (698 tests)
make test-backend      # Backend only (2075+ tests)
```

Docker-dependent backend tests auto-skip when daemon is unavailable.

## Lint

```bash
make lint              # Frontend + Backend
cd frontend && npm run lint
poetry run pre-commit run --all-files --config ./dev_config/python/.pre-commit-config.yaml
```

## Proxy Configuration

### Vite Dev Server (Frontend)
- **VITE_BACKEND_HOST**: Backend address for proxy (default: `127.0.0.1:3000`)
- Proxy routes: `/api` → backend API, `/ws` → WebSocket, `/socket.io` → Socket.IO, `/sockets` → V1 WebSocket
- **Corporate proxy**: `HTTP_PROXY=http://proxy:8080 HTTPS_PROXY=http://proxy:8080 make run`
- Or add to `frontend/.env`: `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY=localhost,127.0.0.1`

### Docker / Sandbox (Backend)
- **config.toml** `[sandbox]` section:
  - `runtime_extra_build_args`: Pass `--build-arg http_proxy=...` for Docker image build
  - `runtime_startup_env_vars`: Set `HTTP_PROXY`/`HTTPS_PROXY` for runtime containers
- Example: `runtime_extra_build_args = ["--build-arg", "http_proxy=http://proxy:8080"]`

### LLM API (LiteLLM Proxy)
- Use `litellm_proxy/` model prefix with `base_url` for LiteLLM proxy
- See config.template.toml for `[llm]` options

## Proxy Cluster (10.0.0.x)

### Discovered Hosts

| IP | SSH (22) | HTTP (80) | HTTPS (443) | Proxy (8080) | Squid (3128) |
|----|----------|-----------|-------------|--------------|--------------|
| 10.0.0.1 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 10.0.0.2 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 10.0.0.10 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 10.0.0.11 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 10.0.0.50 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 10.0.0.100 | ✓ | ✓ | ✓ | ✓ | ✓ |

**Proxy in use**: `http://10.0.0.100:8080` (configured in `frontend/.env`).

### Operating System Detection

OS cannot be determined remotely without SSH access. From this environment:

- **HTTP headers**: Requests to the proxy return no usable Server/OS headers.
- **SSH banner**: Requires SSH credentials; with access, run: `ssh user@10.0.0.100 "uname -a"` to get kernel/OS.

**Manual OS check** (if you have SSH access):

```bash
# Single host
ssh user@10.0.0.100 "uname -a"

# All cluster hosts
for ip in 10.0.0.1 10.0.0.2 10.0.0.10 10.0.0.11 10.0.0.50 10.0.0.100; do
  echo "=== $ip ===" && ssh -o ConnectTimeout=3 user@$ip "uname -a" 2>/dev/null || echo "no access"
done
```

**Likely setup**: Ports 8080/3128 suggest Squid or similar proxy on Linux; typical for corporate proxies.

## SSH Connection

### Git over SSH
- **Default**: OpenHands uses HTTPS URLs with provider tokens (GitHub, GitLab, etc.)
- **SSH clone**: For `git@github.com:user/repo.git`, ensure SSH keys are available in the sandbox:
  - Mount `~/.ssh` via `[sandbox] volumes` in config.toml
  - Or use `runtime_startup_env_vars` to set `GIT_SSH_COMMAND` if needed
- **SSH Microagent**: See `skills/ssh.md` for agent capabilities (ssh, scp, ssh-keygen, etc.)

### Sandbox SSH Access
- Mount host SSH config: `volumes = "/home/user/.ssh:/workspace/.ssh:ro"`
- Or copy keys into workspace before agent runs (less secure)

### Troubleshooting SSH
- `ssh -vvv user@host` for verbose debug
- `chmod 600 ~/.ssh/id_*` for private keys
- `ssh-keygen -R hostname` to fix changed host keys

## Known Limitations

1. **Docker in nested containers**: Use host Docker or native environment for full agent functionality
2. **config.toml**: Gitignored - run `make setup-config-basic` if missing
3. **LLM API key**: Required for conversations - configure before use

## Google Cloud Run

Deploy to Google Cloud:

```bash
# One-time: gcloud auth login && gcloud config set project YOUR_PROJECT_ID
./scripts/deploy-google-cloud.sh [PROJECT_ID] [REGION]
```

Or: `gcloud builds submit --config=cloudbuild.yaml`

**Note**: Cloud Run has no Docker socket. For agent conversations, configure `SANDBOX_REMOTE_RUNTIME_API_URL` in config or use AllHands Remote Runtime.

## File Structure

```
workspace/     # Agent working directory
logs/          # Backend logs
config.toml    # App config (gitignored)
frontend/build # Static assets for backend
cloudbuild.yaml # Google Cloud Build config
```
