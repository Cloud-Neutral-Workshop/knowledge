# Vibe Coding Reference

This repository primarily delivers a web frontend experience and should document product flows, UI boundaries, and integration touchpoints.

Use this page to align AI-assisted coding prompts, repo boundaries, safe edit rules, and documentation update expectations.

## Current code-aligned notes

- Documentation target: `console.svc.plus`
- Repo kind: `frontend`
- Manifest and build evidence: package.json (`dashboard`)
- Primary implementation and ops directories: `src/`, `scripts/`, `tests/`, `config/`, `public/`
- Package scripts snapshot: `dev`, `prebuild`, `build`, `build:static`, `start`, `lint`

## Existing docs to reconcile

- `api/auth.md`
- `api/endpoints.md`
- `api/errors.md`
- `api/overview.md`
- `zh/api/auth.md`
- `zh/api/endpoints.md`
- `zh/api/errors.md`
- `zh/api/overview.md`

## What this page should cover next

- Describe the current implementation rather than an aspirational future-only design.
- Keep terminology aligned with the repository root README, manifests, and actual directories.
- Link deeper runbooks, specs, or subsystem notes from the legacy docs listed above.
- Review prompt templates and repo rules whenever the project adds new subsystems, protected areas, or mandatory verification steps.
