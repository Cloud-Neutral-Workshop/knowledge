# Endpoints

## POST /api/askai

Generate an answer from the configured chat completion provider. If RAG is
initialized, retrieved chunks are also returned.

Request:

```json
{ "question": "How do I deploy?" }
```

Response:

```json
{
  "answer": "...",
  "chunks": [
    {"repo":"...","path":"...","chunk_id":0,"content":"...","metadata":{}}
  ]
}
```

Notes:

- RAG is initialized lazily by the RAG endpoints. If it has not been initialized,
  `"chunks"` will be `null`.

Errors:

- `400` on invalid JSON.
- `500` with `{ "error": "...", "config": {"timeout": <sec>, "retries": <n>} }`.

## POST /api/rag/query

Hybrid retrieval only (no generation). The server currently returns the top 5
chunks.

Request:

```json
{ "question": "backup policy" }
```

Response:

```json
{ "chunks": [ {"repo":"...","path":"...","chunk_id":0,"content":"...","metadata":{}} ] }
```

Errors:

- `400` on invalid JSON
- `500` on unexpected failures
- `4xx/5xx` propagated from embedding provider
- `200` with `"chunks": null` if the RAG service is not initialized

## POST /api/rag/upsert

Upsert pre-embedded documents.

Request (shape only):

```json
{
  "docs": [
    {
      "repo": "...",
      "path": "...",
      "chunk_id": 0,
      "content": "...",
      "embedding": [0.1, 0.2],
      "metadata": {"heading": "Intro"},
      "content_sha": "<sha256>"
    }
  ]
}
```

Response:

```json
{ "rows": 123 }
```

Errors: `503` if the vector store is unavailable.

Notes:

- If the RAG service is not initialized, the response is `200` with `{ "rows": 0 }`.

## POST /api/sync

Sync a Git repository to a local directory.

Request:

```json
{ "repo_url": "https://github.com/org/repo.git", "local_path": "/tmp/repo" }
```

Response:

```json
{ "status": "synced" }
```

Errors:

- `400` on invalid JSON
- `500` when the repo sync fails

## GET /api/users

Returns users from the service database.

## GET /api/nodes

Returns nodes from the service database.

## GET /api/admin/settings

Requires `X-User-Role: admin|operator`.

Response:

```json
{ "version": 3, "matrix": {"moduleA": {"admin": true, "user": false}} }
```

## POST /api/admin/settings

Requires `X-User-Role: admin|operator`.

Request:

```json
{ "version": 3, "matrix": {"moduleA": {"admin": true}} }
```

Response:

```json
{ "version": 4, "matrix": {"moduleA": {"admin": true}} }
```

Conflict:

- `409` with `{ "error": "admin settings version conflict", "version": <current>,
  "matrix": <current> }`

Errors:

- `400` on invalid JSON or unsupported role values in the matrix
- `403` when the caller is not `admin` or `operator`
- `503` when the service database is not initialized
