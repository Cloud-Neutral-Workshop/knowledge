# Developer Guide

This repository primarily delivers a web frontend experience and should document product flows, UI boundaries, and integration touchpoints.

Use this page to document local setup, project structure, test surfaces, and contribution conventions tied to the current codebase.

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
- `development/code-structure.md`
- `development/contributing.md`
- `development/dev-setup.md`
- `development/testing.md`

## What this page should cover next

- Describe the current implementation rather than an aspirational future-only design.
- Keep terminology aligned with the repository root README, manifests, and actual directories.
- Link deeper runbooks, specs, or subsystem notes from the legacy docs listed above.
- Keep setup and test commands tied to actual package scripts, Make targets, or language toolchains in this repository.
