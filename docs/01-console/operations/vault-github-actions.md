# Vault + GitHub Actions for `console.svc.plus`

This note records the Vault OIDC login pattern used by the `console.svc.plus` frontend pipeline.
It focuses on the minimal setup needed for GitHub Actions to read CI/CD secrets from Vault K/V.

## Goal

- Use GitHub Actions OIDC to authenticate to Vault.
- Read CI/CD secrets from `kv/data/CICD`.
- Keep deployment secrets out of GitHub Actions Secrets where possible.

## Required Vault prerequisites

- `jwt` auth mount enabled and configured for GitHub Actions OIDC.
- A policy that can read the `kv/data/CICD` path.
- A JWT role that binds to the `ai-workspace-services/portal` repository.

## Policy

Create a policy that allows read-only access to the shared CICD path:

```bash
export VAULT_ADDR=https://vault.svc.plus
vault login

vault policy write github-actions-console - <<'EOF'
path "kv/data/CICD" {
  capabilities = ["read"]
}
path "kv/metadata/CICD" {
  capabilities = ["read", "list"]
}
EOF
```

## JWT role

The role must bind to the `ai-workspace-services/portal` repository.

Pass a JSON body on stdin so Vault receives `bound_claims` as a map. This role
allows workflows from `main` and `release/*` only:

```bash
vault write auth/jwt/role/github-actions-console - <<'EOF'
{
  "role_type": "jwt",
  "user_claim": "repository",
  "bound_audiences": ["vault"],
  "bound_claims_type": "glob",
  "bound_claims": {
    "repository": "ai-workspace-services/portal",
    "sub": [
      "repo:ai-workspace-services/portal:ref:refs/heads/main",
      "repo:ai-workspace-services/portal:ref:refs/heads/release/*"
    ]
  },
  "token_policies": ["github-actions-console"],
  "token_ttl": "20m",
  "token_max_ttl": "30m"
}
EOF
```

## CI/CD secrets expected in `kv/data/CICD`

The frontend pipeline expects these keys to exist:

- `GHCR_TOKEN`
- `SINGLE_NODE_VPS_SSH_PRIVATE_KEY`
- `INTERNAL_SERVICE_TOKEN`
- `CLOUDFLARE_DNS_API_TOKEN`

## Workflow shape

The GitHub Actions workflow should:

1. Set `permissions.id-token: write`.
2. Use `hashicorp/vault-action@v4`.
3. Authenticate with `method: jwt`.
4. Use `role: github-actions-console`.
5. Read secrets from `kv/data/CICD`.
6. Export the values into the job environment or step outputs.

## SSH key handling

Use the raw OpenSSH private key:

```bash
SSH_KEY="${SINGLE_NODE_VPS_SSH_PRIVATE_KEY}"
```

Then write the key to `~/.ssh/id_rsa` and validate it with `ssh-keygen -y -f`.

## Common error

If Vault returns:

```text
error converting input for field "bound_claims": '' expected a map, got 'string'
```

that means `bound_claims` was passed as a string argument. Re-run the command using the JSON stdin body above. The `-` argument reads JSON from stdin; `@-` is not supported because Vault treats it as a local file named `-`.
