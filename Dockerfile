# joplin-mcp: wraps erickt23/joplin-server-mcp (stdio) with supergateway (HTTP/SSE)
# Built and pushed to registry.mdapi.ch/mdapi/joplin-mcp by GitLab CI.

FROM gitlab.mdapi.ch/mdapi/dependency_proxy/containers/python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs npm curl \
    && rm -rf /var/lib/apt/lists/*

# Install supergateway globally (v7+ required for streamableHttp transport)
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

# streamableHttp transport: stateless per-request, endpoint at POST /mcp
# Replaces sse which crashed on second concurrent connection.
ENTRYPOINT ["supergateway", "--port", "8080", "--outputTransport", "streamableHttp", \
            "--stdio", "python /app/joplin_server_mcp.py"]
