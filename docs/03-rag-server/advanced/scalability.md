# Scalability

## Stateless API

The HTTP service is stateless; you can scale horizontally as long as all instances share the same Postgres database.

## Database considerations

- Each RAG query/upsert creates a new Postgres connection in the current implementation.
- For high throughput, consider adding connection pooling (pgxpool) or using pgbouncer in front of Postgres.

## Cloud Run

Cloud Run is supported out of the box. Tune concurrency and instance limits according to your embedding provider and database capacity.
