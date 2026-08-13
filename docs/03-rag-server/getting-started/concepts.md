# Core Concepts

## Data sources
A **datasource** is a named Git repository and a path within that repo. The CLI syncs repositories and ingests markdown files from these paths.

## Ingestion pipeline
Ingestion consists of:

1. **Sync**: clone or update a Git repository.
2. **Parse**: extract markdown sections and headings.
3. **Chunk**: split content into overlapping text chunks.
4. **Embed**: send chunks to the embedding provider.
5. **Upsert**: store embeddings and metadata in Postgres.

## Hybrid retrieval
Queries are executed using both:

- **Vector similarity** (`pgvector` HNSW index)
- **Full-text rank** (`tsvector` with `zhparser` and `websearch_to_tsquery`)

Scores are blended using `retrieval.alpha`.

## Reranking (optional)
If a reranker endpoint is configured, the candidate list is re-scored before final results.

## Ask AI
`/api/askai` calls a chat completion endpoint. If the RAG service is initialized, it attaches retrieved chunks alongside the answer.
