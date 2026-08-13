# Vault + GitHub Actions（`console.svc.plus`）

这份说明记录 `console.svc.plus` 前端流水线使用 Vault OIDC 取密钥的标准接入方式。
重点是最小可用配置，方便后续直接复用。

## 目标

- 使用 GitHub Actions OIDC 登录 Vault。
- 从 `kv/data/CICD` 读取 CI/CD 密钥。
- 尽量不依赖 GitHub Actions Secrets 存储发布密钥。

## Vault 前置条件

- 已启用并配置 `jwt` auth mount，用于 GitHub Actions OIDC。
- 已创建可读 `kv/data/CICD` 的 policy。
- 已创建绑定到 `ai-workspace-services/portal` 仓库的 JWT role。

## Policy

先创建只读 policy：

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

Role 必须绑定到 `ai-workspace-services/portal` 仓库。

通过标准输入传入 JSON body，确保 Vault 把 `bound_claims` 解析为 map。该 Role
只允许 `main` 和 `release/*` 分支：

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

## `kv/data/CICD` 里需要的键

前端流水线至少会读取这些键：

- `GHCR_TOKEN`
- `SINGLE_NODE_VPS_SSH_PRIVATE_KEY`
- `INTERNAL_SERVICE_TOKEN`
- `CLOUDFLARE_DNS_API_TOKEN`

## 流水线要求

GitHub Actions workflow 应满足：

1. `permissions.id-token: write`
2. 使用 `hashicorp/vault-action@v4`
3. `method: jwt`
4. `role: github-actions-console`
5. 从 `kv/data/CICD` 读取密钥
6. 再把密钥注入到后续构建/部署步骤

## SSH 私钥处理

直接使用 OpenSSH 私钥原文：

```bash
SSH_KEY="${SINGLE_NODE_VPS_SSH_PRIVATE_KEY}"
```

然后把密钥写入 `~/.ssh/id_rsa`，再用 `ssh-keygen -y -f` 验证。

## 常见报错

如果 Vault 报：

```text
error converting input for field "bound_claims": '' expected a map, got 'string'
```

说明 `bound_claims` 被当作字符串传入了。请改用上面的 JSON stdin 写法。参数 `-` 表示从标准输入读取 JSON；不要使用 `@-`，Vault 会把它当作名为 `-` 的本地文件。
