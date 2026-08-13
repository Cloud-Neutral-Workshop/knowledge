# Deployment

This repository is a Go service with API, configuration, runtime operations, and deployment responsibilities.

Use this page to standardize deployment prerequisites, supported topologies, operational checks, and rollback notes.

## Current code-aligned notes

- Documentation target: `rag-server.svc.plus`
- Repo kind: `go-service`
- Manifest and build evidence: go.mod (`rag-server`)
- Primary implementation and ops directories: `cmd/`, `internal/`, `api/`, `deploy/`, `ansible/`, `scripts/`, `tests/`, `example/`, `migrations/`, `sql/`
- Package scripts snapshot: No package.json scripts were detected.

## Existing docs to reconcile

- `Runbook/RAG-Server.md`
- `deployment.md`
- `development/dev-setup.md`
- `getting-started/installation.md`
- `getting-started/quickstart.md`
- `google-cloud-run-howto.md`
- `governance/release-process.md`
- `usage/deployment.md`

## What this page should cover next

- Describe the current implementation rather than an aspirational future-only design.
- Keep terminology aligned with the repository root README, manifests, and actual directories.
- Link deeper runbooks, specs, or subsystem notes from the legacy docs listed above.
- Verify deployment steps against current scripts, manifests, CI/CD flow, and environment contracts before each release.
