# Code Structure

- `cmd/` binaries (`rag-server`, `rag-cli`, `ingest`, `ragbench`)
- `api/` HTTP handlers and route registration
- `internal/` core packages
  - `rag/` ingestion, embedding, retrieval
  - `auth/` JWT middleware and token cache
  - `cache/` Postgres cache store
  - `service/` DB-backed services (users, nodes, admin settings)
- `config/` server config definitions
- `sql/` schema helpers
- `migrations/` DB migrations
- `deploy/` deployment templates
