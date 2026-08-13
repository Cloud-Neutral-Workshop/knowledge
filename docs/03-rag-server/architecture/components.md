# Components

## API layer (`api/`)
- Registers HTTP routes under `/api`.
- Implements RAG endpoints, AskAI, sync, users/nodes, and admin settings.

## Server entry (`cmd/rag-server`)
- Loads config and log level.
- Applies auth middleware and CORS.
- Wires routes and starts HTTP server.

## RAG service (`internal/rag/`)
- Embedding providers: OpenAI-compatible, Ollama, Chutes, BGE.
- Storage: Postgres with pgvector + full-text search.
- Chunking and ingestion pipeline.

## Auth (`internal/auth/`)
- JWT validation middleware.
- Token cache backed by Postgres `hstore` table.

## Cache (`internal/cache/`)
- Postgres-backed cache store for tokens.

## Sync (`internal/rag/sync/`)
- Git repo sync with `go-git`, shallow clone + reset.

## CLI (`cmd/rag-cli`, `cmd/ingest`)
- `rag-cli`: sync + ingest and upsert via API.
- `ingest`: direct ingestion into Postgres (batch utility).
