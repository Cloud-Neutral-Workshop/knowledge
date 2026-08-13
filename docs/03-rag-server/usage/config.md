# Configuration

The server reads a YAML config file and applies environment variable overrides. The
same file can be used by `rag-server` and `rag-cli` (unused fields are ignored).

## Config resolution order

1. `--config <path>` flag
2. `config/rag-server.yaml` if present
3. `config/server.yaml`

> Note: the repo includes `config/rag-server.yaml`, which uses legacy keys (for
> example `vector_db`). The **current** schema uses `global.vectordb` and
> `server.addr`. Use `example/config/server.yaml` as the canonical reference and
> pass `--config` explicitly if both files exist.

## Minimal example

```yaml
server:
  addr: ":8080"
  readTimeout: 30s
  writeTimeout: 30s
  publicUrl: "https://rag-server.svc.plus"
  allowedOrigins:
    - "https://rag-server.svc.plus"

auth:
  enable: false
  authUrl: "https://accounts.svc.plus"
  apiBaseUrl: "https://api.svc.plus"
  publicToken: ""

global:
  cache:
    table: "cache_kv"
    defaultTTL: 5m
  vectordb:
    pgurl: "postgres://user:pass@127.0.0.1:5432/knowledge_db?sslmode=disable"
  proxy: ""
  datasources:
    - name: knowledge
      repo: https://github.com/example/knowledge.git
      path: /

sync:
  repo:
    proxy: "socks5://127.0.0.1:1080"

models:
  embedder:
    provider: "chutes"     # or "ollama"
    models: ["bge-m3"]
    endpoint: "http://127.0.0.1:9000/v1/embeddings"
    token: "${NVIDIA_API_KEY}"
  generator:
    provider: "chutes"
    models: ["deepseek-r1:8b"]
    endpoint: "http://127.0.0.1:9000/v1/chat/completions"
    token: "${NVIDIA_API_KEY}"

embedding:
  max_batch: 64
  dimension: 1024
  max_chars: 8000
  rate_limit_tpm: 120000

chunking:
  max_tokens: 800
  overlap_tokens: 80
  include_exts: [".md", ".mdx"]
  ignore_dirs: [".git", "node_modules", "dist", "build"]

retrieval:
  alpha: 0.5
  candidates: 50

api:
  askai:
    timeout: 100
    retries: 3
```

## Key sections

### server

- `addr`: listen address (default `:8080` if empty).
- `readTimeout`, `writeTimeout`: HTTP timeouts.
- `publicUrl`: used to derive a default CORS origin if none is configured. If
  `allowedOrigins` is empty, the server falls back to `publicUrl`, then to common
  localhost origins.
- `allowedOrigins`: CORS allowlist. Use `*` to allow all origins (credentials
  disabled).
- `baseurl` (rag-cli only): base URL for API calls when `SERVER_URL` is not set.
  If omitted, `rag-cli` derives a URL from `server.addr`.

### auth

- `enable`: toggle auth middleware.
- `authUrl`, `apiBaseUrl`: used by the auth client; the middleware does not call
  external services on each request.
- `publicToken`: passed into the auth client (JWT verification uses internal
  secrets).

### global

- `cache`: Postgres-backed cache table used for token caching.
- `vectordb`: Postgres connection info (either `pgurl` or discrete fields).
- `proxy`: optional outbound proxy for HTTP and Git operations.
- `datasources`: list of Git repos for ingestion (required for `rag-cli` and
  `ingest`).

### sync

- `repo.proxy`: proxy used only for Git operations (overrides `global.proxy` for
  repo sync).

### models

- `embedder`: embedding provider used by RAG queries and ingestion.
- `generator`: chat completion provider used by `/api/askai`.
- `reranker` (optional, in RAG config): supports reranking if `endpoint` is set.
- `models`: can be a single string or a list; the first entry is used.

### embedding / chunking

Tune chunk size, overlap, and embedding limits. See `internal/rag/config` for full
options (including `embed_toc`, `embed_headings`, `by_paragraph`, and
`additional_max_tokens`).

### retrieval

- `alpha`: blend between vector and text scores (0..1).
- `candidates`: number of candidates retrieved before reranking.

### api

- `askai.timeout`: seconds for chat completion requests.
- `askai.retries`: retry count (capped at 3).

## Environment variables

- `PORT`: overrides server listen port.
- `DATABASE_URL` or `PG_URL`: overrides Postgres DSN.
- `SERVER_URL`: base URL for `rag-cli` when not provided in config.
- `CHUTES_API_URL`, `CHUTES_API_MODEL`, `CHUTES_API_TOKEN`: override AskAI model
  settings for OpenAI-compatible providers.

Environment variables are expanded inside the YAML file (for example
`${NVIDIA_API_KEY}` or `$NVIDIA_API_KEY`).
