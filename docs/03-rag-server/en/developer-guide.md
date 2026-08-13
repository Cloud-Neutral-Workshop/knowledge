# Developer Guide

This repository is a Go service with API, configuration, runtime operations, and deployment responsibilities.

Use this page to document local setup, project structure, test surfaces, and contribution conventions tied to the current codebase.

## Current code-aligned notes

- Documentation target: `rag-server.svc.plus`
- Repo kind: `go-service`
- Manifest and build evidence: go.mod (`rag-server`)
- Primary implementation and ops directories: `cmd/`, `internal/`, `api/`, `deploy/`, `ansible/`, `scripts/`, `tests/`, `example/`, `migrations/`, `sql/`
- Package scripts snapshot: No package.json scripts were detected.

## Existing docs to reconcile

- `PATH_VERIFICATION.md`
- `api/auth.md`
- `api/endpoints.md`
- `api/errors.md`
- `api/overview.md`
- `api-reference.md`
- `development/code-structure.md`
- `development/contributing.md`

## What this page should cover next

- Describe the current implementation rather than an aspirational future-only design.
- Keep terminology aligned with the repository root README, manifests, and actual directories.
- Link deeper runbooks, specs, or subsystem notes from the legacy docs listed above.
- Keep setup and test commands tied to actual package scripts, Make targets, or language toolchains in this repository.
