## 四、Vault 三层路径与最小权限

“三层架构”不仅是目录命名，还必须落实为独立 Policy 和 Role 边界。

```text
kv/data/CICD
├── GHCR_USERNAME
└── GHCR_TOKEN

kv/data/CICD/domains/<domain>
├── tls_fullchain_pem_b64
├── tls_cert_pem_b64
├── tls_key_pem_b64
├── tls_ca_pem_b64
└── tls_trust_bundle_pem_b64

kv/data/CICD/<env>
├── VPS_API_KEY
├── GCP_WIF_PROVIDER
├── GCP_DEPLOYER_SERVICE_ACCOUNT
└── 环境基础设施配置

kv/data/<env>/hybrid/control-plane
├── GCP_PROJECT_ID
├── GCP_REGION
├── ARTIFACT_REGISTRY_URL
├── CLOUDFLARE_ACCOUNT_ID
├── PAGES_PROJECT_NAME
├── WORKER_NAME
├── PORTAL_DOMAIN
└── API_DOMAIN

kv/data/<env>/hybrid/deploy/cloudflare
└── CLOUDFLARE_API_TOKEN

kv/data/<env>/hybrid/runtime/edge-gateway
└── JWT_VERIFY_SECRET

kv/data/<env>/hybrid/runtime/accounts
├── DATABASE_SESSION_POOLER_URL
├── DATABASE_TRANSACTION_POOLER_URL  # 可选，仅 Cloud Run 且已验证事务池化兼容性时使用
└── INTERNAL_SERVICE_TOKEN

kv/data/<env>/hybrid/runtime/billing
├── DATABASE_SESSION_POOLER_URL
├── DATABASE_TRANSACTION_POOLER_URL  # 可选，仅 Cloud Run 且已验证事务池化兼容性时使用
├── INTERNAL_SERVICE_TOKEN
└── STRIPE_WEBHOOK_SECRET

kv/data/<env>/hybrid/runtime/content
├── KNOWLEDGE_REPO_URL
├── KNOWLEDGE_REPO_PATH
└── INTERNAL_SERVICE_TOKEN

kv/data/<env>/hybrid/runtime/portal
├── NEXT_PUBLIC_API_URL
└── NEXT_PUBLIC_SUPABASE_ANON_KEY

kv/data/<env>/serverless/supabase
├── PROJECT_REF
├── DATABASE_SESSION_POOLER_URL
├── DATABASE_TRANSACTION_POOLER_URL  # 可选
└── DATABASE_DIRECT_URL               # migration/backup 专用
```

以上按服务拆分的路径是 Cloud Run 和多服务隔离场景的最小权限基线。对于当前 `console-uat` 这类“Caddy + Portal + Accounts + Billing + Content + PostgreSQL”同机 All-in-one，可以使用一个聚合运行包：

```text
kv/data/<env>/hybrid/runtime/
├── DATABASE_SESSION_POOLER_URL
├── DATABASE_TRANSACTION_POOLER_URL  # 可选，不作为 All-in-one 默认
├── ACCOUNTS_INTERNAL_SERVICE_TOKEN
├── BILLING_INTERNAL_SERVICE_TOKEN
├── STRIPE_WEBHOOK_SECRET
├── CONTENT_KNOWLEDGE_REPO_URL
├── CONTENT_KNOWLEDGE_REPO_PATH
├── CONTENT_INTERNAL_SERVICE_TOKEN
├── PORTAL_NEXT_PUBLIC_API_URL
└── PORTAL_NEXT_PUBLIC_SUPABASE_ANON_KEY
```

聚合运行包的规则：

- 可以作为 All-in-one 主机初始化和部署 Job 的统一读取路径；
- `DATABASE_SESSION_POOLER_URL` 可以作为 All-in-one 默认连接，但生产环境仍建议为不同服务使用不同数据库角色；
- `DATABASE_TRANSACTION_POOLER_URL` 只作为 Cloud Run 可选档位，不得未经兼容性验证覆盖 Session pooler；
- `INTERNAL_SERVICE_TOKEN` 不建议在聚合包中使用一个无区分的共享值，优先使用带服务前缀的 Token；
- `NEXT_PUBLIC_*` 只是前端公开构建配置，不是私密凭据，不能因为放在 Vault 就当作 Secret 保护；
- `STRIPE_WEBHOOK_SECRET` 和知识库配置必须限制在受信任的部署/控制面范围内；
- 聚合路径与服务隔离路径是两种运行档位，不应在同一环境无治理地维护两份可变 Secret；需要同时支持时，必须由部署编排器从一个权威来源生成另一种注入格式，并记录版本/校验值。

Vault KV Policy 按路径授权，不能对同一个 KV 数据对象中的单个字段实现可靠的运行时隔离。因此 Cloud Run 服务继续使用 `runtime/accounts`、`runtime/billing`、`runtime/content` 等服务级路径；All-in-one 主机可以使用聚合路径，但不得把该聚合 Role 复用于独立 Cloud Run 服务。

### 域名证书存储与下发路径

公网域名、泛域名和 Caddy ACME 状态统一存储在域名级 Vault 路径：

```text
Vault canonical path:
kv/data/CICD/domains/<domain>

VPS runtime path:
/etc/xcontrol/tls/<domain>/current/
├── fullchain.pem
├── cert.pem
├── key.pem
├── ca.pem
└── trust-bundle.pem
```

当前平台约定中，`kv/data/CICD/domains/<domain>` 是跨 SIT、UAT、PROD 复用的域名证书来源；证书有效期内不因应用发布或主机重建重复申请 ACME 证书。若未来要求环境隔离证书，必须整体切换为 `kv/data/CICD/domains/<env>/<domain>`，不能在同一域名下混用两种布局。

字段约定：

- `tls_fullchain_pem_b64`：完整证书链，供 Caddy 之外的 TLS 服务使用；
- `tls_cert_pem_b64`：叶子证书；
- `tls_key_pem_b64`：域名私钥；
- `tls_ca_pem_b64`：签发 CA/中间链；
- `tls_trust_bundle_pem_b64`：客户端校验用公共根信任包，不能被证书备份任务覆盖。

证书轮换、应用镜像发布和 Cloud Run revision 发布必须相互解耦。证书恢复后，Ansible/部署脚本将 PEM 材料原子写入 `/etc/xcontrol/tls/<domain>/current/`，校验证书、私钥、SAN、签发环境和有效期后再切换 `current`。PEM、私钥和解码后的证书不得写入 Git、GitHub Artifact、Step Summary 或普通部署日志。

### 权限规则

| 身份 | 可读取范围 | 禁止读取 |
|---|---|---|
| `platform-ops-toolkit-<env>` | 当前环境 control-plane、deploy 和必要的 runtime | 其他环境路径 |
| `console-uat-all-in-one` | 当前环境的聚合 `runtime/` | 其他环境、Vault 管理路径、域名证书写权限 |
| Cloudflare deploy job | Cloudflare deploy、Gateway runtime | GCP、Supabase 主密码 |
| `accounts` runtime | `runtime/accounts` | billing、content、Cloudflare Token |
| `billing-service` runtime | `runtime/billing` | GCP 部署凭据 |
| `content-service` runtime | `runtime/content` | Supabase Service Role Key |
| migration job | 数据库迁移专用路径 | Cloudflare 生产凭据 |
| domain TLS rotation/backup job | `kv/data/CICD/domains/<domain>` 写入 | 应用运行时和普通发布 Job 的写权限 |
| VPS bootstrap/runtime | `kv/data/CICD/domains/<domain>` 只读 | 其他域名和环境的写权限 |

`ANON_KEY` 属于前端公开构建配置；`SERVICE_ROLE_KEY`、`DATABASE_DIRECT_URL` 和主数据库密码不得注入普通业务服务。

---

## 五、服务与运行时配置合同

| 服务 | 必需配置 | 运行约束 |
|---|---|---|
| Portal | `NEXT_PUBLIC_API_URL`、必要的公开 Supabase 配置 | 构建阶段注入；禁止注入私密 Key |
| Gateway | JWT 验签 Secret、当前环境 upstream map、超时配置 | Worker environment 独立部署 |
| Accounts | Pooler URL、内部服务 Token、`PORT`/配置模板 | VPS 与 Cloud Run 端口必须一致 |
| Billing | Pooler URL、内部服务 Token、当前环境支付 Secret | 必须校验数据库和内部 Token |
| Content | Knowledge repo URL/path/ref、内部服务 Token、端口 | 镜像或启动阶段必须提供知识内容来源 |

Cloud Run 服务的端口、健康检查路径和必须的环境变量必须在部署前静态校验。不能只依赖 Dockerfile 的 `EXPOSE`。

### 数据库连接

- VPS 日常运行使用 Session pooler `5432`，Vault Key 为 `DATABASE_SESSION_POOLER_URL`；
- Cloud Run 日常运行默认使用 Session pooler；只有应用明确兼容事务池化时，才使用 `DATABASE_TRANSACTION_POOLER_URL` 的 `6543`；
- schema/DDL/`pg_dump` migration 使用独立的 `DATABASE_DIRECT_URL`；如果迁移 runner 不支持 IPv6，则回退到 Session pooler；
- 备份恢复优先使用 Direct，IPv4-only 网络回退到 Session pooler；
- 连接池必须限制最大连接数，避免 Cloud Run 水平扩展打满 Supabase；
- 数据库 URL 不得出现在日志、GitHub Step Summary 或错误信息中。

---

## 六、制品与不可变发布

所有环境都不使用 `latest`、`main` 或运行时动态推导的镜像版本作为实际部署输入。

### 允许的发布标识

```text
<env>-daily-build-YYYY.MM.DD
<env>-daily-build-YYYY.MM.DD-rN
sha-<40 位 full commit SHA>
```

每个服务构建必须提供：

- 不可变 tag；
- 完整 commit SHA tag；
- 镜像 digest；
- 构建来源仓库和 commit；
- 可选的 release manifest。

部署时必须显式传入 `deploy_tag` 或 digest。流水线不得自行把空值替换为 `latest`。

Artifact Registry 至少保留当前部署 digest、上一稳定 digest 和当前候选 digest；`latest` 只能作为指向候选版本的便利别名，不能作为回滚依据。

### 镜像来源

必须在以下两种方案中选择一种并固定：

1. 服务仓库构建并推送到统一 Artifact Registry；
2. 服务仓库构建到 GHCR，目标环境部署前进行受控复制并校验 digest。

不能出现“服务 CI 推送 GHCR，环境 CD 却直接拉取不存在的 Artifact Registry 镜像”的分裂契约。

---
