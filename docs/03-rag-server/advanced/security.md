# Security

## Authentication

Enable auth with `auth.enable: true`. The middleware enforces:

- `Authorization: Bearer <JWT>` header
- `service = "rag-server"` claim

Admin endpoints additionally require `X-User-Role: admin|operator`.

## Secrets

- Store provider tokens in environment variables and reference them in YAML via `${VAR}`.
- Avoid committing secrets into config files.

## CORS

- Configure `server.allowedOrigins` to restrict clients.
- Use `*` only when you understand the implications (credentials disabled).

## Network proxy

If you need outbound proxying (for Git sync or model calls), configure `global.proxy` or `sync.repo.proxy`.
