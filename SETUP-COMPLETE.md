# OpenHands - Setup Complete

This document summarizes the development environment setup and known configuration.

## Quick Start

```bash
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

## Known Limitations

1. **Docker in nested containers**: Use host Docker or native environment for full agent functionality
2. **config.toml**: Gitignored - run `make setup-config-basic` if missing
3. **LLM API key**: Required for conversations - configure before use

## File Structure

```
workspace/     # Agent working directory
logs/          # Backend logs
config.toml    # App config (gitignored)
frontend/build # Static assets for backend
```
