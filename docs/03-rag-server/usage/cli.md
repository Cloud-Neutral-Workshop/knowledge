# CLI

## rag-server

Starts the HTTP API server.

```bash
rag-server [--config <path>] [--log-level <debug|info|warn|error>]
```

- `--config`: path to the YAML configuration file.
- `--log-level`: overrides `log.level` from the config file.

## rag-cli

Synchronizes repositories and ingests markdown files into the server via API.

```bash
rag-cli --config <path> [--file <path>] [--log-level <level>]
```

Environment:

- `SERVER_URL`: base URL for the API (default: from config, or `http://localhost:8080`).

Behavior:

- If `--file` is provided, only that file is embedded and upserted. The file must be
  inside a datasource working directory (typically `/tmp/xcontrol/<datasource>/...`)
  created by `rag-cli` during sync.
- Otherwise, it iterates over `global.datasources` in config, syncs each repo, and
  ingests the markdown files it finds.

## ingest (batch tool)

Direct ingestion into Postgres (no HTTP) using the RAG config:

```bash
ingest --config <path> [--only-repo <name>] [--dry-run] [--max-files <n>] \
  [--migrate-dim] [--concurrency <n>]
```

This tool uses the same chunking and embedding config as the server. Prefer passing an
explicit `--config` path when running from the repo root.

## ragbench (optional)

Benchmark runner for retrieval quality. It expects a YAML input file describing
queries.

```bash
ragbench --in queries.yaml --api http://localhost:8080 --out report.md
```

Note: `ragbench` assumes a response shape that is not identical to the current
`/api/rag/query` response. Use it with a compatible adapter or update the tool before
relying on the metrics.
