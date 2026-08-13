# Architecture

This repository is a Go service with API, configuration, runtime operations, and deployment responsibilities.

Use this page as the canonical bilingual overview of system boundaries, major components, and repo ownership.

## Current code-aligned notes

- Documentation target: `rag-server.svc.plus`
- Repo kind: `go-service`
- Manifest and build evidence: go.mod (`rag-server`)
- Primary implementation and ops directories: `cmd/`, `internal/`, `api/`, `deploy/`, `ansible/`, `scripts/`, `tests/`, `example/`, `migrations/`, `sql/`
- Package scripts snapshot: No package.json scripts were detected.

## Existing docs to reconcile

- `api/overview.md`
- `architecture/components.md`
- `architecture/design-decisions.md`
- `architecture/overview.md`
- `architecture/roadmap.md`
- `development/code-structure.md`

## What this page should cover next

- Describe the current implementation rather than an aspirational future-only design.
- Keep terminology aligned with the repository root README, manifests, and actual directories.
- Link deeper runbooks, specs, or subsystem notes from the legacy docs listed above.
- Keep diagrams and ownership notes synchronized with actual directories, services, and integration dependencies.
