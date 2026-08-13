# Examples

## Ask AI

```bash
curl -s http://localhost:8080/api/askai \
  -H 'Content-Type: application/json' \
  -d '{"question":"What is this service?"}'
```

If RAG has not been initialized yet, the response includes `"chunks": null`.

## RAG query

```bash
curl -s http://localhost:8080/api/rag/query \
  -H 'Content-Type: application/json' \
  -d '{"question":"deployment steps"}'
```

## Upsert documents

`/api/rag/upsert` expects pre-embedded vectors. Typically use `rag-cli` instead. A
minimal shape:

```json
{
  "docs": [
    {
      "repo": "https://github.com/example/knowledge",
      "path": "docs/intro.md",
      "chunk_id": 0,
      "content": "...",
      "embedding": [0.1, 0.2, 0.3],
      "metadata": {"heading": "Intro"},
      "content_sha": "<sha256>"
    }
  ]
}
```

## Sync repository

```bash
curl -s http://localhost:8080/api/sync \
  -H 'Content-Type: application/json' \
  -d '{"repo_url":"https://github.com/example/knowledge.git","local_path":"/tmp/knowledge"}'
```

## List users / nodes

```bash
curl -s http://localhost:8080/api/users
curl -s http://localhost:8080/api/nodes
```
