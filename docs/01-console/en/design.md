# Design

This repository primarily delivers a web frontend experience and should document product flows, UI boundaries, and integration touchpoints.

Use this page to consolidate design decisions, ADR-style tradeoffs, and roadmap-sensitive implementation notes.

## Current code-aligned notes

- Documentation target: `console.svc.plus`
- Repo kind: `frontend`
- Manifest and build evidence: package.json (`dashboard`)
- Primary implementation and ops directories: `src/`, `scripts/`, `tests/`, `config/`, `public/`
- Package scripts snapshot: `dev`, `prebuild`, `build`, `build:static`, `start`, `lint`

## Existing docs to reconcile

- `SEO-WORK-SUMMARY.md`
- `architecture/design-decisions.md`
- `zh/SEO-WORK-SUMMARY.md`
- `zh/architecture/design-decisions.md`

## What this page should cover next

- Describe the current implementation rather than an aspirational future-only design.
- Keep terminology aligned with the repository root README, manifests, and actual directories.
- Link deeper runbooks, specs, or subsystem notes from the legacy docs listed above.
- Promote one-off implementation notes into reusable design records when behavior, APIs, or deployment contracts change.
