# Deployment

## Docker

```bash
docker build -t rag-server:local .
docker run -p 8080:8080 \
  -e CONFIG_PATH=/etc/rag-server/server.yaml \
  -v $(pwd)/config/server.yaml:/etc/rag-server/server.yaml:ro \
  -e DATABASE_URL="postgres://user:pass@host:5432/db?sslmode=disable" \
  rag-server:local
```

## Docker Compose

See `deploy/docker-compose.yaml` for a full local stack (rag-server + stunnel + caddy
+ rag-cli + ragbench). The server expects a mounted config at
`/etc/rag-server/server.yaml`.

## Cloud Run

The Makefile includes a `gcp-deploy` target. For Cloud Run:

- Set `DATABASE_URL` via Secret Manager or env vars.
- Provide `NVIDIA_API_KEY` or your provider token for embeddings and chat completions.
- Ensure the config file is copied into the container and `CONFIG_PATH` is set.

Example:

```bash
gcloud run deploy rag-server-svc-plus \
  --source . \
  --region asia-northeast1 \
  --set-env-vars DATABASE_URL=... \
  --set-env-vars NVIDIA_API_KEY=...
```

## Systemd

A systemd example service exists in `deploy/rag-server.svc.plus/systemd` (for bare-metal or VM setups).
Ensure the config file path matches your deployment layout.
