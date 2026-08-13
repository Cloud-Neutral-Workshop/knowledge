# Architecture Overview

## High-level flow

```
Client
  -> rag-server (Gin HTTP API)
     -> Postgres (pgvector + full-text)
     -> Embedding Provider (OpenAI-compatible)
     -> Chat Completion Provider (OpenAI-compatible)
     -> Git repos (via go-git, optional)
```

## Data flow (RAG query)

1. Client POSTs a question to `/api/rag/query`.
2. Server embeds the question using the configured embedder.
3. Server queries Postgres for vector + full-text candidates.
4. Scores are blended and optionally reranked.
5. Top documents are returned as `chunks`.

## Data flow (Ingestion)

1. `rag-cli` (or `/api/rag/upsert`) embeds content.
2. The server ensures the schema exists.
3. Chunks are upserted into Postgres.
