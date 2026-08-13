# Cloud & Deployment Integrations

## Cloud Run

- The Dockerfile is optimized for Cloud Run.
- Use `DATABASE_URL` and provider tokens (for example `NVIDIA_API_KEY`) as environment variables.
- Mount the config file and set `CONFIG_PATH` if needed.

## Docker Compose

`deploy/docker-compose.yaml` provides an example local stack with:

- `rag-server`
- `stunnel-client` (for database tunneling)
- `caddy` (reverse proxy)
- `rag-cli` and `ragbench`

## Systemd

`deploy/rag-server.svc.plus/systemd` includes a unit file for running rag-server on VMs or bare metal. Ensure the config path and environment variables match your deployment layout.
