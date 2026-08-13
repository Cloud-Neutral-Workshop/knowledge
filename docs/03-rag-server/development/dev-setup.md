# Dev Setup

## Prerequisites

- Go 1.24+
- PostgreSQL 16+ with `vector`, `zhparser`, `hstore`

## Install dependencies

```bash
make init
```

## Configure

Copy example config:

```bash
cp example/config/server.yaml config/rag-server.yaml
```

Update `global.vectordb.pgurl` and model endpoints.

## Run locally

```bash
make dev
```

## Database schema

The ingestion pipeline will auto-create schema on first upsert. If you prefer manual setup, ensure your schema matches the runtime text search configuration (`zhcn_search`).
