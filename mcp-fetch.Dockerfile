FROM node:22-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-venv curl && \
    rm -rf /var/lib/apt/lists/*

# Create Python venv and install mcp-server-fetch
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir mcp-server-fetch

# Pre-install supergateway globally
RUN npm install -g supergateway

EXPOSE 8000

CMD ["supergateway", "--stdio", "/opt/venv/bin/python -m mcp_server_fetch", "--port", "8000"]
