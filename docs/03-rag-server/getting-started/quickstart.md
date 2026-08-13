# Quickstart (10 minutes)

This guide gets the server running locally with a minimal config and a test upsert.

## 1) Prerequisites

- Go 1.24+ (for local builds)
- PostgreSQL 16+
- PostgreSQL extensions: `vector`, `zhparser`, `hstore`

> Note: the ingestion code auto-creates schema using `zhparser`. The `sql/schema.sql` file uses `pg_jieba` and `jieba_search` and may not match runtime expectations; use it only if you align the text search configuration.

## 2) Create a config file

Copy the example config and update database and model settings:

```bash
cp example/config/server.yaml config/server.yaml
```

Then edit at least:

- `global.vectordb.pgurl`
- `models.embedder.endpoint` and `models.generator.endpoint`
- `models.embedder.token` / `models.generator.token` (if needed)

## 3) Start Postgres

Ensure Postgres is running and the required extensions are available:

```bash
psql "${DATABASE_URL}" -c "CREATE EXTENSION IF NOT EXISTS vector;"
psql "${DATABASE_URL}" -c "CREATE EXTENSION IF NOT EXISTS zhparser;"
psql "${DATABASE_URL}" -c "CREATE EXTENSION IF NOT EXISTS hstore;"
```

## 4) Run the server

```bash
make dev
# or
# go run cmd/rag-server/main.go --config config/server.yaml
```

The server listens on `:8080` by default.

## 5) Upsert one file (optional)

Use `rag-cli` to embed and upload a markdown file:

```bash
# Build the CLI
make build

# Create a temp datasource directory that matches your config
mkdir -p /tmp/xcontrol/knowledge
cat <<'DOC' > /tmp/xcontrol/knowledge/hello.md
# Hello

This is a test document.
DOC

# Upsert the file
SERVER_URL=http://localhost:8080 ./rag-cli --config config/server.yaml --file /tmp/xcontrol/knowledge/hello.md
```

## 6) Query

```bash
curl -s http://localhost:8080/api/rag/query \
  -H 'Content-Type: application/json' \
  -d '{"question":"hello"}' | jq
```
