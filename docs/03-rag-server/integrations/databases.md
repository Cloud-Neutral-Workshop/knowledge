# Databases

## PostgreSQL requirements

The RAG store relies on PostgreSQL with these extensions:

- `vector` (pgvector)
- `zhparser` (full-text search config `zhcn_search`)
- `hstore` (token cache)

## Schema creation

There are two paths:

1. **Automatic (recommended)**: The ingestion pipeline (`rag-cli` or `/api/rag/upsert`) calls `store.EnsureSchema`, which creates the `documents` table, indexes, and the `zhcn_search` text search config.
2. **Manual**: `sql/schema.sql` creates a similar schema but uses `pg_jieba` and `jieba_search`. If you use this file, make sure your query path and text search configuration align with the runtime code.

## Tables

- `documents`: embeddings, metadata, and `tsvector` for hybrid retrieval.
- `cache_kv`: unlogged cache table storing token validation results (hstore).
- `admin_settings`: stored via migrations in `migrations/`.

## Connection configuration

Preferred config key:

- `global.vectordb.pgurl`: full connection DSN.

Alternative keys (used when `pgurl` is empty):

- `pg_host`, `pg_port`, `pg_user`, `pg_password`, `pg_db_name`, `pg_sslmode`
