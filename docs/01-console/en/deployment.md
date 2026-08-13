# Deployment

## Production Baseline

- Runtime: `Caddy + Docker Compose`
- Deploy host: `root@jp-xhttp-contabo.svc.plus`
- Public domains:
  - `www.svc.plus`
  - `console.svc.plus`
- Canonical public origin: `https://www.svc.plus`
- Frontend release workflow: `.github/workflows/pipeline.yaml`

## Operating Model

The frontend is built in GitHub Actions and shipped as a prebuilt `linux/amd64` image. The host only pulls the image and starts containers; it does not build locally.

`yarn prebuild` now generates only console-owned marketing artifacts. `/docs` and `/blogs` no longer bundle `knowledge/` or synced markdown content into the frontend image. Those routes fetch rendered content from `docs.svc.plus` at request time through the server-side `docsServiceClient`.

The stack is static-first:

- Caddy serves `/_next/static/*` and public assets from a shared read-only volume.
- The Next.js standalone container serves dynamic HTML, auth endpoints, and API proxy routes. Static assets and hashed CSS/JS files are extracted by the `frontend-assets` helper task, so the runtime no longer needs to compile anything on the single-node host.
- `docs.svc.plus` is the source of truth for rendered docs/blog pages; the browser does not call it directly.

Releases are orchestrated through `.github/workflows/pipeline.yaml`. That workflow builds/pushes the image, renders `.env.runtime` including `DOCS_SERVICE_URL` / `DOCS_SERVICE_INTERNAL_URL`, and ships `docker-compose.yml`, `Caddyfile`, and the runtime env file to the host. The control-plane DNS automation then updates Cloudflare DNS for the release domains (via `scripts/github-actions/update-release-dns.sh`) so both `www.svc.plus` and `console.svc.plus` resolve to the same environment.

The release contract now uses:

- `CANONICAL_DOMAIN=www.svc.plus`
- `SERVED_DOMAINS=www.svc.plus,console.svc.plus`

Validation must pass for both domains. A release is incomplete if either host serves a different runtime version, static asset family, or `dashboardUrl`.

This baseline is intentional for the weak-IO single-node host `root@jp-xhttp-contabo.svc.plus`. No images are built on the target machine, keeping the deployment lightweight: the host only logs into GHCR, pulls the `dashboard` image, extracts assets into `frontend_static`, and starts `dashboard` plus `caddy` containers via `docker compose`.

`docs.svc.plus` is now the dedicated docs/blog service for the frontend delivery path.

## Related Docs

- `usage/deployment.md`
- `governance/release-process.md`
- `development/dev-setup.md`
