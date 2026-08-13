# FAQ

## Which config file should I edit?

Use `example/config/server.yaml` as the canonical schema. Copy it to `config/rag-server.yaml` and edit values there.

## Do I need Redis?

No. Token caching uses Postgres `hstore`.

## Why is my retrieval empty?

Check that embeddings were created and the vector store is reachable. `rag-cli` logs embedding and upsert counts.
