# Vibe Coding Reference

This repository is a Go service with API, configuration, runtime operations, and deployment responsibilities.

Use this page to align AI-assisted coding prompts, repo boundaries, safe edit rules, and documentation update expectations.

## Current code-aligned notes

- Documentation target: `accounts.svc.plus`
- Repo kind: `go-service`
- Manifest and build evidence: go.mod (`account`)
- Primary implementation and ops directories: `cmd/`, `internal/`, `api/`, `accountsvc/`, `deploy/`, `ansible/`, `scripts/`, `tests/`, `sql/`, `config/`
- Package scripts snapshot: No package.json scripts were detected.

## Existing docs to reconcile

- `Runbook/Fix-Agent-404-And-UUID-Change.md`
- `api/auth.md`
- `api/endpoints.md`
- `api/errors.md`
- `api/overview.md`

## What this page should cover next

- Describe the current implementation rather than an aspirational future-only design.
- Keep terminology aligned with the repository root README, manifests, and actual directories.
- Link deeper runbooks, specs, or subsystem notes from the legacy docs listed above.
- Review prompt templates and repo rules whenever the project adds new subsystems, protected areas, or mandatory verification steps.
