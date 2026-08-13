# Deployment

This repository is a Go service with API, configuration, runtime operations, and deployment responsibilities.

Use this page to standardize deployment prerequisites, supported topologies, operational checks, and rollback notes.

## Current code-aligned notes

- Documentation target: `accounts.svc.plus`
- Repo kind: `go-service`
- Manifest and build evidence: go.mod (`account`)
- Primary implementation and ops directories: `cmd/`, `internal/`, `api/`, `accountsvc/`, `deploy/`, `ansible/`, `scripts/`, `tests/`, `sql/`, `config/`
- Package scripts snapshot: No package.json scripts were detected.

## Existing docs to reconcile

- `Runbook/Feature-Sandbox-Mode-and-Sync-Fix.md`
- `Runbook/Fix-Agent-404-And-UUID-Change.md`
- `Runbook/Fix-CloudRun-Stunnel-Startup-Failure.md`
- `Runbook/Fix-Rotating-UUID-Sync-Archive-2026-02-06.md`
- `Runbook/README.md`
- `Runbook/Security-Scrubbing-Archive-2026-02-06.md`
- `SMTP_GMAIL_SETUP.md`
- `development/dev-setup.md`

## What this page should cover next

- Describe the current implementation rather than an aspirational future-only design.
- Keep terminology aligned with the repository root README, manifests, and actual directories.
- Link deeper runbooks, specs, or subsystem notes from the legacy docs listed above.
- Verify deployment steps against current scripts, manifests, CI/CD flow, and environment contracts before each release.
