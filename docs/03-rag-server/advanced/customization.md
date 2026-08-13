# Customization

## Add new API endpoints

- Add handlers under `api/` and wire them in `api/register.go`.
- Use the shared `ragSvc` if you need access to retrieval.

## Extend ingestion

- Modify chunking behavior in `internal/rag/ingest`.
- Add metadata enrichment in `BuildChunks` or before upsert.

## Support new model providers

Implement a new embedder in `internal/rag/embed` and add a provider switch in `internal/rag/service.go` and `cmd/rag-cli`.
