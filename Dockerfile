# joplin-mcp: wraps erickt23/joplin-server-mcp (stdio) with supergateway (HTTP/SSE)
# Built and pushed to registry.mdapi.ch/mdapi/joplin-mcp by GitLab CI.

FROM gitlab.mdapi.ch/mdapi/dependency_proxy/containers/python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs npm curl \
    && rm -rf /var/lib/apt/lists/*

# Install supergateway globally
RUN npm install -g supergateway

WORKDIR /app

# Pin the server script at a known commit to avoid surprise breakage
ARG JOPLIN_MCP_COMMIT=main
ADD https://raw.githubusercontent.com/erickt23/joplin-server-mcp/${JOPLIN_MCP_COMMIT}/joplin_server_mcp.py /app/joplin_server_mcp.py

# Install Python dependencies
RUN pip install --no-cache-dir \
    "mcp>=1.0.0" \
    "joppy>=1.0.0" \
    "pydantic>=2.0.0" \
    "httpx>=0.24.0"

EXPOSE 8080

# supergateway wraps the stdio MCP server and exposes it as SSE on :8080
# --oauth2Bearer is set at runtime via MCP_AUTH_TOKEN env var passed through CMD
ENTRYPOINT ["supergateway", "--port", "8080", "--outputTransport", "sse", \
            "--stdio", "python /app/joplin_server_mcp.py"]
