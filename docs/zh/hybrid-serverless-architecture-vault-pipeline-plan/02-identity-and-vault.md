## 三、统一身份与凭据架构

GitHub Actions 使用 GitHub OIDC 作为工作负载身份根，但不同平台分别建立信任关系：

```text
GitHub Actions Job
  │
  │ GitHub OIDC
  │
  ├─ audience=vault
  │    └─ Vault JWT Role
  │         └─ 读取目标环境 Secret
  │
  ├─ GCP Workload Identity Federation
  │    └─ 短期 GCP 部署凭据
  │
  ├─ AWS IAM OIDC → STS
  │    └─ 短期 AWS 凭据
  │
  └─ Azure Entra Federated Credential
       └─ 短期 Azure Access Token
```

这些身份关系是并行的，不应设计成“先登录 Vault，再由 Vault 代替所有云厂商登录”。不同身份系统通常要求不同的 `audience`，因此应分别请求和交换 OIDC Token。

### 1. GitHub Actions 权限

涉及联邦身份的 Job 必须显式声明：

```yaml
permissions:
  contents: read
  id-token: write
```

每个环境都应使用独立的 GitHub Environment、部署分支/Tag 限制和必要的人工审批。

### 2. Vault JWT

Vault JWT 用于读取：

- VPS API Key（当 VPS 供应商不支持 GitHub OIDC 时）；
- Cloudflare 部署 Token；
- Supabase 连接信息；
- 应用运行时 Secret；
- 迁移和初始化任务所需的短期数据凭据。

Vault Role 必须绑定：

- GitHub repository；
- `ref` 或 GitHub Environment；
- `job_workflow_ref`；
- OIDC `audience`；
- 最小 TTL 和不可续期的 batch token。

### 3. GCP Workload Identity Federation

GCP WIF 用于：

- Cloud Run 部署和更新；
- Artifact Registry 镜像读写；
- 获取部署输出和 revision 信息。

不在 Vault 中保存长期 `GCP_SA_KEY_JSON`。部署 Service Account 与 Cloud Run 运行时 Service Account 必须分离。

### 4. AWS 和 Azure 扩展

如果后续引入 AWS：

```text
GitHub OIDC → AWS IAM OIDC Provider → STS AssumeRoleWithWebIdentity
```

如果后续引入 Azure：

```text
GitHub OIDC → Microsoft Entra Federated Identity Credential
```

AWS、Azure 的 Role/Identity 只授予对应环境和资源所需权限，不回退使用长期 Access Key 或 Client Secret。

---
