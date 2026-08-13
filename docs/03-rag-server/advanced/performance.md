# Performance

## Retrieval performance

- Vector search uses HNSW (`documents_embedding_idx`).
- Full-text search uses a GIN index on `content_tsv`.
- Retrieval blends vector and text scores using `retrieval.alpha`.

## Embedding throughput

Tune these settings:

- `embedding.max_batch`
- `embedding.max_chars`
- `embedding.rate_limit_tpm`

## Chunking strategy

Smaller chunks improve recall but increase embedding cost. Adjust:

- `chunking.max_tokens`
- `chunking.overlap_tokens`
- `chunking.additional_max_tokens` (if used)

## Token cache

When auth is enabled, validated tokens are cached in Postgres to reduce auth overhead. Ensure `global.cache.defaultTTL` is sized to match token lifetimes.
