# UAT on Serverless 极简零成本架构规划与工程落地指南

> **InfoQ 架构师深度专栏**  
> **目标系统**：`ai-workspace-service` 矩阵（`portal`, `edge-gateway`, `accounts`, `billing-service`, `content-service`, `postgresql`）  
> **技术矩阵**：Cloudflare Pages + Cloudflare Worker + GCP Cloud Run (Scale-to-0) + Supabase Cloud Free + HashiCorp Vault (`vault.svc.plus`)  
> **核心原则**：**“数据持久沉淀、计算按需生死、凭据统一托管、开发测试零成本 ($0/月)”**

---

## 📌 一、 规划背景与设计哲学

传统 UAT（User Acceptance Testing）环境往往面临两难：
1. **常驻机器成本浪费**：为了偶尔的联调和测试，长期开着多台云主机与数据库，每月白白浪费几十到上百美元；
2. **每次重新搭建耗时费力**：如果完全销毁，每次测试又要重新建表、导种子数据，严重影响研发效率。

本方案提出 **“数据持久化 + 计算按需生死”** 的 Serverless UAT 体系：
* **数据持久层 (Permanent Store)**：使用 **Supabase Cloud Free** 永久保存 UAT 专属的 Schema、Mock 用户与测试工作区数据，**数据永远不丢失，且免去日常数据库维护成本**；
* **无服务器计算层 (Ephemeral Compute)**：Go 微服务使用 **GCP Cloud Run**（默认缩容至 0 实例，闲置 $0 计费），配合定时流水线每日 20:00 彻底销毁服务，09:00 或按需拉起；
* **边缘接入与网关层 (Edge Tier)**：前端使用 **Cloudflare Pages**，网关使用 **Cloudflare Worker**，完全享受全球免费配额；
* **统一凭据中枢 (Single Source of Truth)**：所有云厂商凭据统一托管在 **HashiCorp Vault (`https://vault.svc.plus`)**，实现零本地硬编码与端到端自动化注入。

---

## 🔐 二、 Vault KV 路径规划规范 (`https://vault.svc.plus`)

遵循平台 Vault 三层架构规范，所有 UAT Serverless 凭据归档在 **`kv/data/uat/serverless/`** 路径下：

```text
kv/data/uat/serverless/
├── cloudflare/                 # Cloudflare 认证与域名配置
│   ├── CLOUDFLARE_ACCOUNT_ID   # 账户 ID
│   ├── CLOUDFLARE_API_TOKEN    # 部署专用 Token (Pages & Worker 权限)
│   ├── CLOUDFLARE_ZONE_ID      # svc.plus Zone ID
│   ├── PAGES_PROJECT_NAME      # "ai-workspace-portal-uat"
│   ├── WORKER_NAME             # "edge-gateway-uat"
│   ├── UAT_PORTAL_DOMAIN       # "uat-console.svc.plus"
│   └── UAT_API_DOMAIN          # "uat-api.svc.plus"
│
├── gcp/                        # GCP Cloud Run 部署凭据
│   ├── GCP_PROJECT_ID          # "ai-workspace-uat-project"
│   ├── GCP_REGION              # "asia-east1"
│   ├── GCP_SA_KEY_JSON         # Service Account JSON (具备 Cloud Run Admin 权限)
│   └── ARTIFACT_REGISTRY_URL   # "asia-east1-docker.pkg.dev/ai-workspace-uat/serverless"
│
├── supabase/                   # Supabase Cloud UAT 数据库连接
│   ├── PROJECT_REF             # Supabase 项目 ID (如 abcd1234efgh)
│   ├── PROJECT_URL             # "https://abcd1234efgh.supabase.co"
│   ├── ANON_KEY                # 前端鉴权匿名 Key
│   ├── SERVICE_ROLE_KEY        # 后端微服务管理员 Key
│   ├── DB_PASSWORD             # 数据库主密码
│   ├── DATABASE_DIRECT_URL     # "postgres://postgres:PWD@db.abcd1234efgh.supabase.co:5432/postgres"
│   └── DATABASE_POOLER_URL     # "postgres://postgres.abcd1234efgh:PWD@aws-0-asia-east1.pooler.supabase.com:6543/postgres?pgbouncer=true"
│
└── app-secrets/                # 业务级通用密钥
    ├── JWT_SECRET              # 统一 JWT 验签密钥 (与 edge-gateway 及 accounts 共享)
    ├── STRIPE_WEBHOOK_SECRET   # UAT 测试 Stripe Webhook 签名
    └── TIMEOUT_MS              # "2500"
```

---

## 🗺️ 三、 微服务与基础设施部署映射

```mermaid
graph TD
    subgraph 接入层 (Cloudflare Edge)
        User[QA / 开发者] -->|访问| Portal[portal: Cloudflare Pages<br/>uat-console.svc.plus<br/>💰 $0 / 无限带宽]
        User -->|API 请求| Gateway[edge-gateway: Cloudflare Worker<br/>uat-api.svc.plus<br/>💰 $0 / 10万请求免费]
    end

    subgraph 计算层 (GCP Cloud Run - 每日按需创建/夜间销毁)
        Gateway -->|/api/v1/accounts/*| Acc[accounts: Cloud Run (min=0, max=2)]
        Gateway -->|/api/v1/billing/*| Bill[billing-service: Cloud Run (min=0, max=2)]
        Gateway -->|/api/v1/content/*| Content[content-service: Cloud Run (min=0, max=2)]
    end

    subgraph 存储层 (Supabase Cloud Free - 永久保存)
        Acc -->|Supavisor 连接池 6543| Supa[(Supabase PostgreSQL: ai-workspace-uat<br/>• 永久保存测试用户与 Schema<br/>• 每周定时心跳防休眠)]
        Bill -->|Supavisor 连接池 6543| Supa
        Content -->|Supavisor 连接池 6543| Supa
    end

    subgraph 统一凭据中枢
        Vault[(vault.svc.plus: kv/data/uat/serverless/*)] -.->|动态注入| Gateway
        Vault -.->|动态注入| Acc
        Vault -.->|动态注入| Bill
        Vault -.->|动态注入| Content
        Vault -.->|动态注入| Portal
    end
```

| 仓库名称 | 本地路径 | UAT 目标载体 | 运行时配置 (源自 Vault) |
| :--- | :--- | :--- | :--- |
| **`portal`** | `ai-workspace-service/portal` | **Cloudflare Pages** | `NEXT_PUBLIC_API_URL=https://uat-api.svc.plus`<br>`NEXT_PUBLIC_SUPABASE_ANON_KEY` |
| **`edge-gateway`** | `ai-workspace-service/edge-gateway.svc.plus` | **Cloudflare Worker** | `PRIMARY_UPSTREAM=Cloud Run URL`<br>`JWT_SECRET` |
| **`accounts`** | `ai-workspace-service/accounts` | **GCP Cloud Run** | `min-instances=0, max-instances=2`<br>`DATABASE_URL=Supabase Pooler 6543` |
| **`billing-service`** | `ai-workspace-service/billing-service` | **GCP Cloud Run** | `min-instances=0, max-instances=2`<br>`DATABASE_URL=Supabase Pooler 6543` |
| **`content-service`** | `ai-workspace-service/content-service` | **GCP Cloud Run** | `min-instances=0, max-instances=2`<br>`DATABASE_URL=Supabase Pooler 6543` |
| **`postgresql`** | `ai-workspace-service/postgresql` | **Supabase Cloud Free** | 预置测试库表与种子数据，永久持久化保存 |

---

## 🛠️ 四、 独立流水线与自动化模块规划

### 1. `platform-ops-toolkit` 独立编排目录结构
```text
platform-ops-toolkit/
├── .github/
│   └── workflows/
│       ├── uat-serverless-orchestrator.yml   # 统一入口流水线 (Manual + PR + Cron 09:00)
│       ├── uat-daily-cleanup.yml             # 每天 20:00 定时销毁 Cloud Run 临时服务
│       └── uat-supabase-keepalive.yml        # 每周一/四防休眠心跳
└── scripts/
    └── serverless_uat/
        ├── deploy_orchestrator.py            # 主调度 Python 控制器 (从 Vault 取密并编排)
        ├── deploy_cloudrun_services.sh       # 部署 Go 容器 (min=0)
        ├── deploy_cloudflare_worker.sh       # 部署 edge-gateway
        ├── deploy_cloudflare_pages.sh        # 部署 portal
        ├── destroy_ephemeral_compute.sh      # 销毁 Cloud Run 实例与历史镜像
        └── supabase_keepalive.sh             # 轻量级 REST API 心跳探测
```

### 2. Ansible 角色扩展 (`playbooks/roles/saas/serverless_uat/`)
```text
playbooks/roles/saas/serverless_uat/
├── defaults/
│   └── main.yml                              # 默认配置 (Vault 路径、Cloud Run 规格)
├── tasks/
│   ├── main.yml                              # 主任务入口 (依次加载部署任务)
│   ├── fetch_vault_credentials.yml           # 从 Vault 提取 Cloudflare/GCP/Supabase 凭据
│   ├── deploy_cloudrun.yml                   # 编排部署 Go 容器 (min=0, max=2)
│   ├── deploy_cloudflare.yml                 # 编排部署 Worker 与 Pages
│   ├── smoke_test.yml                        # 自动化冒烟测试
│   └── destroy.yml                           # 销毁临时计算任务
└── README.md                                 # 角色使用手册
```

### 3. IaC 模块扩展 (`iac_modules/terraform-hcl-standard/modules/serverless_uat/`)
```text
iac_modules/terraform-hcl-standard/modules/serverless_uat/
├── main.tf                                   # Cloud Run v2 服务与 Cloudflare 资源声明
├── variables.tf                              # 输入变量 (vault_addr, env, image_tags)
├── outputs.tf                                # 输出各服务访问端点
└── README.md                                 # 模块说明文档
```

---

## 💰 五、 成本效益与落地 Checklist

### 成本效益表
| 资源项目 | 运行策略 | 实际月度开销 |
| :--- | :--- | :--- |
| **Cloudflare Pages (UAT 前端)** | 全球 CDN 静态托管，无限带宽 | **$0.00** |
| **Cloudflare Worker (UAT 网关)** | 每天 < 1000 次请求，在 10 万次免费池内 | **$0.00** |
| **GCP Cloud Run (UAT Go 容器)** | 白天工作 8 小时按需冷启动，夜间彻底销毁 | **$0.00** |
| **Supabase Cloud (UAT 数据库)** | 500MB 免费空间，每周定时心跳保活 | **$0.00** |
| **HashiCorp Vault (凭据中枢)** | 托管在现有 `vault.svc.plus` 统一集群 | **$0.00** |
| **总计月度开发/测试预算** | **全套完整闭环的现代化 UAT 环境** | **$0.00 / 月 (绝对零成本)** |

### 生产实施 Checklist
- [ ] 在 `vault.svc.plus` 创建 `kv/data/uat/serverless/` 下的 4 个密钥路径并填充凭据；
- [ ] 在 `platform-ops-toolkit` 落地 `scripts/serverless_uat/` 部署脚本与 GitHub Actions 流水线；
- [ ] 在 `playbooks/roles/saas/serverless_uat` 落地 Ansible 角色；
- [ ] 在 `iac_modules` 落地 Terraform UAT 模块；
- [ ] 执行首次端到端 UAT 验证与自动化冒烟测试。
