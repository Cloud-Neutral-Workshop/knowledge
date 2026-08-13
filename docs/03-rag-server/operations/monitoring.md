# Monitoring

## Health checks

- `GET /health`
- `GET /healthz`
- `GET /ping` (only when auth is enabled)

When auth is enabled these routes are excluded from auth checks.

## Metrics

The service does not expose metrics endpoints by default. Rely on platform metrics (Cloud Run, Kubernetes) and Postgres monitoring.
