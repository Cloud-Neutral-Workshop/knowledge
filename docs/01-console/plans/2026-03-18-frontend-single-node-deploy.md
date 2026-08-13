# Console Frontend Single-Node Deployment Design

## Scope

- Repository: `console.svc.plus`
- Target host: `root@cn-console.svc.plus`
- Public domains:
  - `cn-console.svc.plus`
  - `cn-console.onwalk.net`
- Delivery mode: `GitHub Actions + GHCR + Caddy + Docker Compose`

This document defines the deployment baseline for the China-facing frontend node. The source of truth is this upstream repository. The control-plane repository may consume the repo through git submodule, but should not become the primary place where this deployment design lives.

## Objective

Provide an independent frontend deployment pipeline for `console.svc.plus` that fits the current host constraints:

- the host IO is weak
- the host must not build Docker images locally
- the frontend should run in a static-first mode where possible
- deployment logic should stay in checked-in scripts, not be embedded in GitHub Actions YAML

The result should support repeatable releases, quick rollback by image tag, and minimal work on the target machine.

## Constraints

### Host constraints

- `cn-console.svc.plus` is a single-node host
- deployment user is `root`
- local image build on the host is explicitly disallowed
- IO pressure should be minimized during release

### Application constraints

- `console.svc.plus` is not a purely static site
- auth routes, same-origin API proxy routes, and selected dynamic pages still require a running Next.js server
- some `NEXT_PUBLIC_*` variables are compiled into the frontend bundle at image build time
- `prebuild` pulls documentation and `knowledge` content, so CI must prepare those inputs before building the image

### Repository constraints

- workflow YAML should remain orchestration-only
- service-local operational notes should remain in this repo
- downstream control repos can reference this repo through submodule updates after upstream changes are pushed

## Recommended Topology

### 1. CI build on GitHub Actions

The workflow builds a single `linux/amd64` image in GitHub Actions and pushes it to GHCR.

Reasons:

- matches the target host architecture
- avoids multi-arch overhead for this single-node release path
- avoids local host build IO and CPU pressure
- keeps release artifacts immutable and rollback-friendly

### 2. Runtime on the host

Use `docker compose` with three services:

- `dashboard`: Next.js standalone runtime
- `frontend-assets`: one-shot container that copies static files from the image into a Docker volume
- `caddy`: TLS termination, redirect handling, static file serving, and reverse proxy

This keeps the host work limited to:

- image pull
- asset extraction from the image
- container restart

### 3. Static-first request flow

Caddy serves:

- `/_next/static/*`
- checked-in `public/` assets

Next.js serves:

- HTML responses
- `/api/*` routes
- auth/session flows
- dynamic pages that still depend on server runtime

This reduces repeat disk reads and network hops for the bulk of frontend traffic while preserving the dynamic behavior the app still needs.

## Build-Time vs Runtime Configuration

### Build-time config

These values must be available during Docker build because the frontend bundle reads them directly:

- `NEXT_PUBLIC_APP_BASE_URL`
- `NEXT_PUBLIC_SITE_URL`
- `NEXT_PUBLIC_LOGIN_URL`
- `NEXT_PUBLIC_DOCS_BASE_URL`
- `NEXT_PUBLIC_RUNTIME_ENVIRONMENT`
- `NEXT_PUBLIC_RUNTIME_REGION`
- `NEXT_PUBLIC_GISCUS_*`
- `NEXT_PUBLIC_PAYPAL_CLIENT_ID`
- `NEXT_PUBLIC_STRIPE_*`

These are injected in GitHub Actions as Docker build args.

### Runtime config

These values are rendered into `.env.runtime` and copied to the host:

- upstream service URLs such as `ACCOUNT_SERVICE_URL`
- tokens used only on the server side
- Cloudflare analytics credentials
- internal service token
- runtime hostname hints

This separation avoids rebuilding for purely server-side secret or endpoint changes when the public frontend bundle does not change.

## Knowledge and Docs Handling

Current decision:

- `knowledge/` is cloned during CI
- the cloned content is included in the image build context
- the built image contains the resulting content needed by the current frontend

Reason:

- `prebuild` depends on this material
- the host should not fetch or generate content during deployment

Temporary nature:

- today the frontend still carries docs-related payload
- later, when `docs.svc.plus` becomes an API/service, docs delivery should move out of the frontend image
- that future change should reduce image size and simplify the runtime responsibilities of `console.svc.plus`

## Domain Handling

Primary domain:

- `cn-console.svc.plus`

Secondary domain:

- `cn-console.onwalk.net`

Current routing decision:

- Caddy accepts both domains
- requests for `cn-console.onwalk.net` are redirected permanently to `cn-console.svc.plus`

Reason:

- avoid duplicate canonical origins
- keep cookie and login behavior centered on one primary host
- simplify SEO and observability interpretation

## Release Workflow

### Trigger

Independent workflow:

- `.github/workflows/service_release_frontend-deploy.yml`

### Steps

1. check out repository
2. clone `knowledge`
3. build and push `ghcr.io/<owner>/dashboard:<tag>`
4. render `.env.runtime`
5. upload compose/caddy/env files to the host
6. log in to GHCR on the host
7. pull the new image
8. run `frontend-assets`
9. start or refresh `dashboard` and `caddy`
10. verify both domains

### Why separate from the existing image workflow

The existing image workflow is broader and oriented toward generic image publishing. This single-node frontend workflow needs tighter control over:

- build-time public env injection
- production deployment sequencing
- SSH-based single-host rollout
- host-specific runtime file rendering

So the frontend release path should remain explicit and independent.

## Rollback Model

Rollback unit:

- image tag reference in `.env.runtime`

Rollback steps:

1. set `FRONTEND_IMAGE` to a previous known-good tag
2. rerun `frontend-assets`
3. restart `dashboard` and `caddy`
4. verify `cn-console.svc.plus`

This avoids rebuilding and keeps rollback cheap on the weak-IO host.

## Security and Secret Handling

Secrets must not be committed to the repo. The workflow should consume:

- `SINGLE_NODE_VPS_SSH_PRIVATE_KEY`
- service tokens
- vault tokens
- internal service token
- optional Cloudflare credentials

Public defaults and non-secret values belong in checked-in examples or GitHub repository/environment variables. Secret-only values stay in GitHub Secrets and are rendered into the host runtime env during deployment.

## Operational Risks

### Risk 1: build-time public env mismatch

If GitHub environment variables are incomplete, the image may build successfully but the frontend can render wrong links or lose third-party integration IDs.

Mitigation:

- keep `.env.example` aligned
- document required GitHub `vars`
- keep the build args list explicit

### Risk 2: image layout drift

If the Docker image no longer contains `/app/dashboard/static` or `/app/dashboard/public`, the `frontend-assets` step fails.

Mitigation:

- keep asset extraction paths documented
- update deploy scripts whenever Dockerfile output layout changes

### Risk 3: docs payload growth

Bundling docs and `knowledge` into the frontend image increases image size.

Mitigation:

- accept it temporarily
- revisit once `docs.svc.plus` is externalized

### Risk 4: single-node blast radius

The host handles both reverse proxy and app runtime. Misconfiguration affects the whole frontend surface.

Mitigation:

- keep compose simple
- keep Caddy config minimal
- use image-tag rollback

## Future Follow-Up

### Near term

- populate required GitHub `vars` and `secrets`
  - run the workflow against `root@cn-console.svc.plus`
- validate DNS, TLS, static assets, login flow, and upstream API proxy behavior

### Later

- move docs delivery out of the frontend image after `docs.svc.plus` is service/API based
- consider splitting static assets to object storage or CDN if traffic grows
- evaluate whether the host should keep only Caddy plus one app container, or whether docs can be removed entirely from this runtime

## Source of Truth Rule

For this deployment design:

- upstream repo source of truth: `console.svc.plus`
- service-local design note location: `docs/plans/`
- control-plane repo role: consume via git submodule after upstream commit is pushed

Do not move the primary design ownership to the control-plane repository.
