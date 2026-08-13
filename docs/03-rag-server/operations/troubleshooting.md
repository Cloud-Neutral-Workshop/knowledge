# Troubleshooting

## AskAI returns 500 with "unsupported protocol scheme"

Cause: generator endpoint is empty.

Fix:

- Set `models.generator.endpoint` in config, or
- Provide `CHUTES_API_URL` env var.

## RAG query returns empty chunks

Possible causes:

- No documents were ingested
- Embedding provider not configured
- Database connection missing

Check:

- `global.vectordb.pgurl` or `DATABASE_URL`
- `models.embedder.endpoint`

## Database errors: missing text search config

If you see `zhcn_search` missing, ensure:

- `zhparser` extension is installed
- Schema was created by the runtime ingestion path (not `sql/schema.sql` unless updated)

## 401 / 403 errors

- Ensure `Authorization: Bearer <token>` header is present
- Token must contain `service = "rag-server"`
- For admin endpoints, set `X-User-Role: admin` or `operator`

## Config file not found

- Confirm `--config` path
- Or place the config at `config/server.yaml`
- In containers, set `CONFIG_PATH` and mount the file into the image
