# Deployment Runbook

## Scope

- Runtime: `console.svc.plus`
- Topology: `Caddy + Docker Compose + GitHub Actions`
- Deploy host: `root@jp-xhttp-contabo.svc.plus`
- Public domains:
  - `https://www.svc.plus`
  - `https://console.svc.plus`
- Canonical public origin: `https://www.svc.plus`

## Current Delivery Model

The production frontend is deployed as a prebuilt container image from GitHub Actions.

- The target host does not build images locally.
- The workflow builds an `linux/amd64` image and pushes it to `ghcr.io/<owner>/dashboard:<sha>`.
- The host only performs `docker login`, `docker compose pull`, static asset extraction, and `docker compose up`.
- `/docs` and `/blogs` fetch their content from `docs.svc.plus` at runtime; the frontend image no longer packs `knowledge/` or synced markdown payloads.
- Static assets are extracted from the image into a shared Docker volume so Caddy can serve `/_next/static/*` and checked-in public files directly.

This is intentionally static-first for the current weak-IO single-node host. Dynamic HTML, auth routes, and API proxy routes still run through the Next.js container, but docs/blog content delivery is now delegated to `docs.svc.plus`.

## Control Plane & DNS Stage

The control repo (`github-org-x-evor`) tracks `console.svc.plus` through `console.svc.plus.code-workspace` and keeps the `subrepos/accounts.svc.plus` pointer in sync via `skills/cross-repo-upstream-submodule-sync`. Releases resolve metadata with that workspace and the `config/single-node-release` manifests. After `.github/workflows/pipeline.yaml` finishes pushing the new image, the control-plane DNS automation calls `scripts/github-actions/update-release-dns.sh` to update Cloudflare DNS so the new endpoint is reachable through the current production host `jp-xhttp-contabo.svc.plus`.

## Runtime Layout

Remote directory:

```bash
/opt/console-svc-plus
```

Files deployed there:

```bash
docker-compose.yml
Caddyfile
.env.runtime
```

Containers:

- `dashboard`: Next.js standalone runtime on port `3000`
- `frontend-assets`: one-shot task that copies `static/` and `public/` into a shared volume
- `caddy`: TLS termination and reverse proxy

## GitHub Actions Inputs

Workflow:

```text
.github/workflows/pipeline.yaml
```

Secrets required:

- `SINGLE_NODE_VPS_SSH_PRIVATE_KEY`
- `OPENCLAW_GATEWAY_TOKEN` if used
- `VAULT_TOKEN` if used
- `AI_GATEWAY_ACCESS_TOKEN` if used
- `INTERNAL_SERVICE_TOKEN` if used
- `CLOUDFLARE_DNS_API_TOKEN` for the Cloudflare DNS stage
- `CLOUDFLARE_API_TOKEN` if homepage Cloudflare analytics are enabled at runtime

Repository/environment variables recommended:

- `CANONICAL_DOMAIN`
- `SERVED_DOMAINS`
- `APP_BASE_URL`
- `NEXT_PUBLIC_APP_BASE_URL`
- `NEXT_PUBLIC_SITE_URL`
- `NEXT_PUBLIC_LOGIN_URL`
- `NEXT_PUBLIC_DOCS_BASE_URL`
- `ACCOUNT_SERVICE_URL`
- `NEXT_PUBLIC_ACCOUNT_SERVICE_URL`
- `SERVER_SERVICE_URL`
- `NEXT_PUBLIC_SERVER_SERVICE_URL`
- `RUNTIME_HOSTNAME`
- `DEPLOYMENT_HOSTNAME`
- `DOCS_SERVICE_URL`
- `DOCS_SERVICE_INTERNAL_URL`
- `NEXT_PUBLIC_RUNTIME_ENVIRONMENT`
- `NEXT_PUBLIC_RUNTIME_REGION`
- `NEXT_PUBLIC_GISCUS_*`
- `NEXT_PUBLIC_STRIPE_*`
- `NEXT_PUBLIC_PAYPAL_CLIENT_ID`
- `CLOUDFLARE_ZONE_TAG` if homepage Cloudflare analytics are enabled at runtime
- `CLOUDFLARE_DNS_ZONE_TAG` only for single-domain manual DNS override; the GitHub Actions DNS stage resolves zones from each domain automatically

## Release Flow

1. GitHub Actions checks out the repo.
2. Docker builds the frontend image with the public `NEXT_PUBLIC_*` values needed at build time.
3. The image is pushed to GHCR.
4. The workflow updates Cloudflare DNS for the release domain.
5. The workflow renders `.env.runtime`, including the canonical public origin and both served frontend domains.
6. The workflow uploads `docker-compose.yml`, `Caddyfile`, and `.env.runtime` to the host.
7. The host pulls the new image, refreshes the static asset volume, and starts `dashboard + caddy`.
8. The workflow verifies both `www.svc.plus` and `console.svc.plus`, and fails the release if either domain serves a different runtime version.

## Verification Commands

Local syntax checks:

```bash
cd /Users/shenlan/workspaces/cloud-neutral-toolkit/console.svc.plus
bash -n scripts/github-actions/render-frontend-runtime-env.sh
bash -n scripts/github-actions/deploy-frontend-single-node.sh
cp deploy/single-node/.env.runtime.example deploy/single-node/.env.runtime
docker compose -f deploy/single-node/docker-compose.yml --env-file deploy/single-node/.env.runtime config >/tmp/console-compose.rendered.yaml
rm -f deploy/single-node/.env.runtime
python3 - <<'PY'
from pathlib import Path
import yaml
yaml.safe_load(Path('.github/workflows/pipeline.yaml').read_text())
print('workflow yaml ok')
PY
```

Remote checks:

```bash
ssh root@jp-xhttp-contabo.svc.plus "cd /opt/console-svc-plus && docker compose --env-file .env.runtime ps"
ssh root@jp-xhttp-contabo.svc.plus "curl -fsSI -H 'Host: www.svc.plus' http://127.0.0.1/"
ssh root@jp-xhttp-contabo.svc.plus "curl -fsSI -H 'Host: console.svc.plus' http://127.0.0.1/"
curl -fsSIL https://www.svc.plus
curl -fsSIL https://console.svc.plus
```

## Failure Signatures

- `docker login ghcr.io` fails
  The workflow token or package visibility is wrong.
- `frontend-assets` fails
  The image layout changed and no longer contains `/app/dashboard/static` or `/app/dashboard/public`.
- `www.svc.plus` or `console.svc.plus` returns `502`
  Caddy is up, but the `dashboard` container failed or is not reachable on port `3000`.

## Rollback

1. Re-run the workflow with a previous known-good image tag.
2. Or update `/opt/console-svc-plus/.env.runtime` and set `FRONTEND_IMAGE=ghcr.io/<owner>/dashboard:<previous-tag>`.
3. Restart the services:

```bash
ssh root@jp-xhttp-contabo.svc.plus "cd /opt/console-svc-plus && docker compose --env-file .env.runtime run --rm frontend-assets"
ssh root@jp-xhttp-contabo.svc.plus "cd /opt/console-svc-plus && docker compose --env-file .env.runtime up -d dashboard caddy"
```

4. Verify `https://www.svc.plus` and `https://console.svc.plus` again before closing the incident.
