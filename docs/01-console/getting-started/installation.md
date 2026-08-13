# Installation

## Purpose

- Set up the local development environment for `console.svc.plus`.
- Define the assistant and integrations defaults without hardcoding gateway values into the UI.

## Environment setup

1. Copy the example file:

```bash
cp .env.example .env
```

2. Use `/Users/shenlan/workspaces/cloud-neutral-toolkit/openclaw-deploy-example/.env` as the reference source for deployment-aligned values when available.

## Assistant and integrations variables

These variables are read on the server side and used to prefill:

- the homepage AI assistant
- the sidebar assistant dialog
- the `/panel/api` integrations page

| Variable | Used by | Notes |
|---|---|---|
| `OPENCLAW_GATEWAY_REMOTE_URL` | OpenClaw assistant | Preferred remote WebSocket endpoint, for example `wss://openclaw.svc.plus:443` |
| `OPENCLAW_GATEWAY_TOKEN` | OpenClaw assistant | Gateway token used by the server-side assistant bridge |
| `VAULT_SERVER_URL` | Vault integration | Base Vault address for connectivity checks and defaults |
| `VAULT_NAMESPACE` | Vault integration | Optional namespace when Vault Enterprise namespaces are used |
| `VAULT_TOKEN` | Vault integration | Token used for Vault probe requests |
| `APISIX_AI_GATEWAY_URL` | APISIX AI Gateway integration | Base HTTP(S) endpoint for AI gateway probing |
| `AI_GATEWAY_ACCESS_TOKEN` | APISIX AI Gateway integration | Access token used for gateway probe requests |

## Behavior

- These values are not hardcoded into React components.
- UI forms can still be overridden per request or per session when needed.
- Empty values simply disable prefill; they do not break the page layout.

## Related documents

- `../README.md`
- `../usage/config.md`
