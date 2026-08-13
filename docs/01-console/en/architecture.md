# Architecture

This repository primarily delivers a web frontend experience and should document product flows, UI boundaries, and integration touchpoints.

Use this page as the canonical bilingual overview of system boundaries, major components, and repo ownership.

## Current code-aligned notes

- Documentation target: `console.svc.plus`
- Repo kind: `frontend`
- Manifest and build evidence: package.json (`dashboard`)
- Primary implementation and ops directories: `src/`, `scripts/`, `tests/`, `config/`, `public/`
- Package scripts snapshot: `dev`, `prebuild`, `build`, `build:static`, `start`, `lint`

## Existing docs to reconcile

- `api/overview.md`
- `architecture/components.md`
- `architecture/design-decisions.md`
- `architecture/overview.md`
- `architecture/roadmap.md`
- `development/code-structure.md`
- `zh/api/overview.md`
- `zh/architecture/components.md`

## What this page should cover next

- Describe the current implementation rather than an aspirational future-only design.
- Keep terminology aligned with the repository root README, manifests, and actual directories.
- Link deeper runbooks, specs, or subsystem notes from the legacy docs listed above.
- Keep diagrams and ownership notes synchronized with actual directories, services, and integration dependencies.
