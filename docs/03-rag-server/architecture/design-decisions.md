# Design Decisions

## PostgreSQL + pgvector
Using Postgres keeps storage and text search in one system. pgvector enables fast vector similarity with an HNSW index.

## Hybrid retrieval (vector + text)
Vector similarity is combined with full-text rank (`tsvector` + `websearch_to_tsquery`). This improves recall for exact keywords and mixed-language content.

## Markdown-first ingestion
The ingestion pipeline is optimized for documentation and knowledge bases stored as markdown, with heading-aware chunking.

## OpenAI-compatible model APIs
Both embedding and generator providers are treated as OpenAI-compatible HTTP APIs, enabling easy swapping across providers like NVIDIA, Chutes, or Ollama.

## Stateless HTTP service
The server is stateless and relies on Postgres for persistence and token caching. This keeps horizontal scaling simple.
