# Authentication

## Middleware behavior

When `auth.enable` is true, a global middleware validates every request except health
endpoints.

- Header: `Authorization: Bearer <token>`
- Required JWT claim: `service = "rag-server"`
- Cache: validated tokens are cached in Postgres (`cache_kv` by default)

Skipped paths: `/health`, `/healthz`, `/ping`.

## Roles and admin endpoints

`/api/admin/settings` requires the caller to be **admin** or **operator**. The role
is read from:

- `X-User-Role` header, or
- `X-Role` header

Accepted values: `admin`, `operator`, `user` (case-insensitive). Only `admin` and
`operator` are permitted for admin endpoints; other values return `403 Forbidden`.

## When auth is disabled

If `auth.enable` is false, no auth middleware is applied and `/health` and
`/healthz` return a simplified response with `auth: "disabled"`.
