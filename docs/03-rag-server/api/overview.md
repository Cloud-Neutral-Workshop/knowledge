# API Overview

- Base path: `/api`
- Content type: `application/json`
- Authentication: optional JWT Bearer token (see `auth.md`)
- Responses: JSON objects, with errors returned as `{ "error": "..." }`

Primary endpoints:

- RAG: `/api/rag/query`, `/api/rag/upsert`
- Ask AI: `/api/askai`
- Sync: `/api/sync`
- Admin settings: `/api/admin/settings`
- Metadata: `/api/users`, `/api/nodes`

Health checks are outside `/api` at `/health`, `/healthz`, and `/ping` (ping only
when auth is enabled).
