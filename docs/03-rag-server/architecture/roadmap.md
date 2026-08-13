# Roadmap (Proposed)

This file lists potential improvements based on current code behavior. Treat as a living document.

- **Config unification**: align `config/rag-server.yaml`, `example/config/server.yaml`, and runtime schema expectations.
- **OpenAPI spec**: publish a formal API contract under `docs/api/`.
- **Connection pooling**: introduce pgx pool or pgbouncer guidance for high throughput.
- **Config-driven retrieval**: expose `k` in `/api/rag/query` instead of hardcoding 5.
