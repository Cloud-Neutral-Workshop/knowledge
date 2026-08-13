# Design

This repository is a Go service with API, configuration, runtime operations, and deployment responsibilities.

Use this page to consolidate design decisions, ADR-style tradeoffs, and roadmap-sensitive implementation notes.

## Current code-aligned notes

- Documentation target: `rag-server.svc.plus`
- Repo kind: `go-service`
- Manifest and build evidence: go.mod (`rag-server`)
- Primary implementation and ops directories: `cmd/`, `internal/`, `api/`, `deploy/`, `ansible/`, `scripts/`, `tests/`, `example/`, `migrations/`, `sql/`
- Package scripts snapshot: No package.json scripts were detected.

## Existing docs to reconcile

- `IMPLEMENTATION_GUIDE.md`
- `TOKEN_AUTH_SUMMARY.md`
- `architecture/design-decisions.md`

## What this page should cover next

- Describe the current implementation rather than an aspirational future-only design.
- Keep terminology aligned with the repository root README, manifests, and actual directories.
- Link deeper runbooks, specs, or subsystem notes from the legacy docs listed above.
- Promote one-off implementation notes into reusable design records when behavior, APIs, or deployment contracts change.
