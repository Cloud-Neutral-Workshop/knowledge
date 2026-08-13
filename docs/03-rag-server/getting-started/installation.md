# Installation

## Local (Go)

```bash
make init
make build
```

This produces `rag-server` and `rag-cli` binaries in the repository root.

## Docker

The repo includes a Dockerfile for Cloud Run-style images:

```bash
docker build -t rag-server:local .
docker run -p 8080:8080 \
  -e PORT=8080 \
  -e DATABASE_URL="postgres://user:pass@host:5432/db?sslmode=disable" \
  rag-server:local
```

The container entrypoint looks for a config file at `/etc/rag-server/server.yaml`
by default and will copy from `/app/config` if present.

## Configuration file locations

The server resolves config in this order:

1. `--config <path>` flag
2. `config/rag-server.yaml` if present (legacy filename)
3. `config/server.yaml`

Prefer `config/server.yaml` for new deployments.

For container deployments, use `CONFIG_PATH=/etc/rag-server/server.yaml` to point
the process at the mounted config.
