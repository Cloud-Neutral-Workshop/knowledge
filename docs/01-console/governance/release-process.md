# Release Process

This page tracks release summaries for published versions of the public web console served under `www.svc.plus` and `console.svc.plus`.

## Current Release

### v0.2

Release tag: `v0.2`  
Release branch: `release/v0.2`  
Published commit: `0fab89e`

#### Highlights

- Introduced the new XWorkmate workspace with a denser assistant layout, cleaner shell, and improved entry flow.
- Added the OpenClaw assistant workspace and pairing bridge, including configurable origin override and more stable pairing fallback behavior.
- Unified navigation and AI entry points with a persistent assistant sidebar and refined panel routing.
- Added the latest blog shortcuts on the homepage and improved guest and registration messaging.
- Expanded docs with bilingual structure updates, stronger OIDC guidance, and setup/readme cleanup.
- Fixed build stability issues, including `next-mdx-remote` vulnerability-related build failures and Yarn dependency metadata alignment.

#### New Features

- Launched the XWorkmate workspace and polished its workspace entry and layout.
- Added OpenClaw assistant integration, pairing bridge support, integration probe API, and integration defaults handling.
- Added XScopeHub MCP visibility on the services page.
- Displayed the latest 7 blog article titles in homepage shortcuts.

#### Improvements

- Split observability into a tri-view workspace and refined panel assistant routing.
- Unified navigation structure and persistent AI sidebar behavior.
- Improved login and registration flows by using server-resolved account service URLs.
- Guest and demo access must not expose any backing account identity in public UI or session payloads.
- Added vault-backed token lookup for integrations.

#### Docs And Setup

- Added bilingual docs coverage and restructured the docs entry points.
- Rewrote the OIDC authentication guide with fuller setup instructions.
- Updated setup guidance and simplified README structure.

#### Build And Dependency Fixes

- Updated and aligned `next-mdx-remote` usage for secure builds.
- Removed conflicting npm lockfile state and aligned Yarn dependency metadata for reproducible builds.

## Notes

- GitHub Release: `https://github.com/x-evor/console.svc.plus/releases/tag/v0.2`
- Related docs: `docs/README.md`, `docs/en/README.md`, `docs/zh/README.md`
- Release validation must verify both `www.svc.plus` and `console.svc.plus` against the same `releaseImageRef`, `releaseImageTag`, and `releaseCommit`.
- `www.svc.plus` is the canonical public domain for metadata, sitemap, `dashboardUrl`, and shared links.
