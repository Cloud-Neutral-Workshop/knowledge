# AI Providers

The server uses **OpenAI-compatible** HTTP APIs for both embeddings and chat completions. Provider selection is based on config.

## Embedding providers

Selection logic (current code):

- `provider: "ollama"` -> Ollama embeddings
- `provider: "chutes"` -> Chutes-compatible embeddings
- otherwise:
  - if `models.embedder.models[0]` is set -> OpenAI-compatible embeddings
  - else -> BGE-compatible embeddings

Config fields:

- `models.embedder.endpoint`
- `models.embedder.token`
- `models.embedder.models` (first entry is used)
- `embedding.dimension`, `embedding.max_batch`, `embedding.max_chars`, `embedding.rate_limit_tpm`

## Chat completion providers (Ask AI)

`/api/askai` reads model settings from the config file and environment variables:

- `CHUTES_API_URL` (endpoint)
- `CHUTES_API_MODEL`
- `CHUTES_API_TOKEN`

If these are unset, it falls back to values in the config file (`models.generator`).

## Reranker (optional)

If `models.reranker.endpoint` is configured, the retrieval pipeline will rerank candidates using the configured endpoint.
