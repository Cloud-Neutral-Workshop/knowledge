# console.svc.plus Web Console Architecture

## Scope

`console.svc.plus` is the browser-facing control plane. It is a Next.js App Router application that combines public pages, docs browsing, account/admin panels, and a BFF layer that forwards requests to downstream services. It never reads PostgreSQL or Prometheus directly for billing or usage.

## Architecture

```mermaid
flowchart TB
  subgraph Pages["src/app pages"]
    Root["/ -> landing page"]
    Docs["/docs, /docs/[collection], /docs/[collection]/[...slug]\nDocs reader"]
    Auth["/login, /register, /email-verification, /logout\nAuth flows"]
    Panel["/panel/*\nUser / admin console"]
    Tools["/editor/*, /download/*, /cloud_iac/*, /xworkmate/*\nProduct tools"]
    Content["/blogs/*, /services/*, /support/*, /prices, /about, /privacy, /terms, /[slug]"]
    Admin["/dashboard/cms\nCMS/admin entry"]
  end

  subgraph BFF["src/app/api route handlers"]
    AuthAPI["/api/auth/*"]
    AdminAPI["/api/admin/*"]
    AgentAPI["/api/agent-server/[...segments]\n/api/agent/[...segments]"]
    RagAPI["/api/rag/query\n/api/askai"]
    UtilAPI["/api/users\n/api/ping\n/api/content-meta\n/api/render-markdown\n/api/dl-index/*\n/api/marketing/home-stats\n/api/integrations/*\n/api/moltbot/chat\n/api/openclaw/assistant\n/api/task/[...segments]\n/api/xworkmate/profile"]
    GuestAPI["/api/guest/*"]
  end

  Accounts["accounts.svc.plus"]
  Rag["rag-server.svc.plus"]
  DocsSvc["docs.svc.plus"]
  Grafana["observability.svc.plus / Grafana"]
  External["Other upstream services"]
  Subscription["/panel/subscription\nUsage / billing panel"]

  AuthAPI --> Accounts
  AdminAPI --> Accounts
  AgentAPI --> Accounts
  RagAPI --> Rag
  UtilAPI --> DocsSvc
  UtilAPI --> External
  SandboxAPI --> Accounts
  Subscription --> Accounts
  Subscription -.-> Grafana
```

## Frontend Routes

| Route family | Path | Purpose |
| --- | --- | --- |
| Home | `/` | Public landing page and site entry |
| Docs | `/docs`, `/docs/[collection]`, `/docs/[collection]/[...slug]` | Documentation reader, sidebar, and TOC |
| Auth | `/login`, `/register`, `/email-verification`, `/logout` | Sign in / sign up / email verification / session cleanup |
| Panel | `/panel`, `/panel/account`, `/panel/agent`, `/panel/api`, `/panel/appearance`, `/panel/ldp`, `/panel/management`, `/panel/subscription`, `/panel/[...segments]` | Signed-in account and admin console |
| Tools | `/editor`, `/editor/wechat`, `/editor/xiaohongshu`, `/download`, `/download/[...segments]`, `/cloud_iac`, `/cloud_iac/[provider]`, `/cloud_iac/[provider]/[service]`, `/xworkmate`, `/xworkmate/admin`, `/xworkmate/integrations` | Product tools and service explorers |
| Content | `/blogs`, `/blogs/[...slug]`, `/services`, `/services/openclaw`, `/services/insight`, `/support`, `/support/discussions`, `/about`, `/prices`, `/privacy`, `/terms`, `/[slug]` | Marketing / informational pages |
| Admin / CMS | `/dashboard/cms` | CMS or content-management entry |
| Error pages | `/404`, `/500` | Static error surfaces |

## BFF / API Routes

| API family | Path | Purpose | Upstream target |
| --- | --- | --- | --- |
| Auth | `/api/auth/login`, `/api/auth/register`, `/api/auth/register/send`, `/api/auth/register/verify`, `/api/auth/verify-email`, `/api/auth/verify-email/send`, `/api/auth/session`, `/api/auth/token/exchange` | Login, registration, token exchange, session lookup | `accounts.svc.plus/api/auth/*` |
| MFA | `/api/auth/mfa/status`, `/api/auth/mfa/setup`, `/api/auth/mfa/verify`, `/api/auth/mfa/disable` | TOTP setup and verification | `accounts.svc.plus/api/auth/*` |
| OAuth / billing | `/api/auth/oauth/login/[provider]`, `/api/auth/stripe/checkout`, `/api/auth/stripe/portal`, `/api/auth/subscriptions`, `/api/auth/subscriptions/cancel` | OAuth redirects and billing actions | `accounts.svc.plus/api/auth/*` |
| Admin | `/api/admin/settings`, `/api/admin/homepage-video`, `/api/admin/users/*`, `/api/admin/blacklist/*` | Account admin operations | `accounts.svc.plus/api/*` |
| Agent bridge | `/api/agent-server/[...segments]`, `/api/agent/[...segments]` | Agent registry/status and legacy alias | `accounts.svc.plus` |
| RAG | `/api/rag/query`, `/api/askai` | Retrieval and answer generation | `rag-server.svc.plus` |
| Guest / demo runtime | `/api/guest/binding` | Guest read-only node resolution for demo access | `accounts.svc.plus/api/sandbox/binding` |
| Content / docs | `/api/content-meta`, `/api/render-markdown`, `/api/blogs/latest`, `/api/dl-index/*` | Docs/content rendering and download manifests | docs / CDN / download service |
| Integrations | `/api/integrations/defaults`, `/api/integrations/probe`, `/api/marketing/home-stats` | Integration defaults, health probes, marketing metrics | config-dependent external services |
| Misc | `/api/ping`, `/api/users`, `/api/xworkmate/profile`, `/api/task/[...segments]`, `/api/openclaw/assistant`, `/api/moltbot/chat`, `/api/render-markdown` | Health, user lookup, profile, task and assistant proxies | `accounts.svc.plus`, internal API, task services |

## Auth and Session Notes

- Browser calls use the session cookie and BFF logic in `src/server/account/session.ts`.
- Service-to-service calls use `INTERNAL_SERVICE_TOKEN` when configured.
- `api/agent-server/[...segments]` keeps caller `Authorization` untouched when an agent token is already present.
- `api/agent-server/[...segments]` forwards the dashboard session token for browser-driven calls.

## Dependencies

- `accounts.svc.plus` for identity, profile, sandbox, billing, and admin actions.
- `accounts.svc.plus` for authoritative usage and billing summaries sourced from PostgreSQL.
- `rag-server.svc.plus` for RAG query and AskAI.
- `docs.svc.plus` for docs content and navigation data.
- `observability.svc.plus` for Grafana dashboards and operational views only.
- CDN / external providers for content, analytics, and integration checks.

## Notes

- Route groups in parentheses, such as `(auth)`, are Next.js organizational folders and do not appear in the public URL.
- The BFF layer is the main place where console-specific auth shaping, cookie management, and upstream proxying happen.
- The subscription panel displays usage and billing data from accounts only and treats Grafana as an embedded observability surface, not a billing source.
