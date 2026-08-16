## 九、数据库、迁移与种子数据

### 数据层原则

- 目标态是 Supabase 作为每个环境的持久化数据源；
- 当前过渡态允许 `console-uat.onwalk.net` 使用本地 PostgreSQL 承载完整控制面，但必须明确标记为迁移前状态，并完成备份、迁移、校验和回滚预案；
- 计算层可以销毁，数据库 Schema 和测试数据不随之销毁；
- 同一阶段的 VPS 与 Cloud Run 必须使用同一个数据源；迁移期间禁止本地 PostgreSQL 与 Supabase 无明确一致性方案的双写；
- 如果要做灾备复制，必须单独定义一致性、冲突和恢复策略。

### 部署前后顺序

```text
验证 Supabase 项目
  ↓
执行 core migration
  ↓
执行可选 migration
  ↓
执行幂等 seed
  ↓
部署服务
  ↓
执行数据库连接和关键 API 验证
```

Migration job 应使用独立 Vault Role 和最小数据库权限。migration 失败必须停止发布，不得让服务在半迁移状态下对外提供目标环境流量。

### 数据库连接矩阵：运行时与迁移分离

| 场景 | 推荐连接 | Vault Key | 使用边界 |
|---|---|---|---|
| VPS 日常运行 | Session pooler `5432`；IPv4-only 时最稳 | `DATABASE_SESSION_POOLER_URL` | Accounts/Billing 长期运行连接 |
| Cloud Run 日常运行 | Session pooler；代码兼容事务池化时再用 Transaction pooler `6543` | `DATABASE_SESSION_POOLER_URL` / `DATABASE_TRANSACTION_POOLER_URL` | 默认 Session；Transaction 需关闭或验证 prepared statement/session state 依赖 |
| schema/DDL/`pg_dump` 迁移 | Direct connection；无 IPv6 时可用 Session pooler | `DATABASE_DIRECT_URL` | 只读 source + 目标写入，单向执行 |
| 备份恢复 | Direct 优先；IPv4-only 时使用 Session pooler | `DATABASE_DIRECT_URL` / `DATABASE_SESSION_POOLER_URL` | 禁止使用 Transaction pooler |

Canonical Vault 路径：

```text
kv/data/<env>/serverless/supabase
├── PROJECT_REF
├── DATABASE_SESSION_POOLER_URL
├── DATABASE_TRANSACTION_POOLER_URL  # 可选
└── DATABASE_DIRECT_URL               # migration/backup 专用
```

`DATABASE_DIRECT_URL` 不进入普通业务运行时 Secret。部署编排器根据部署档位把
`DATABASE_SESSION_POOLER_URL` 或经验证的 `DATABASE_TRANSACTION_POOLER_URL` 注入
Accounts/Billing；migration job 独立读取 `DATABASE_DIRECT_URL`。VPS 和 Cloud Run
在同一环境必须连接同一个 Supabase 数据库，不能一边读写本地 PostgreSQL、一边读写
Supabase，也不能在没有一致性方案时双写。

---

## 十、Gateway、Portal 与域名合同

### Gateway

Gateway 必须使用明确的目标环境 Worker environment，不能在当前环境部署失败时回退到其他环境配置。

Gateway 必须按服务维护主备映射，而不是使用一个全局 primary/fallback。当前参考实现为：

```text
accounts  -> Accounts VPS  -> Accounts Cloud Run
billing   -> Billing VPS   -> Billing Cloud Run
content   -> Content VPS   -> Content Cloud Run
```

其他 Micro SaaS 按同一合同扩展服务键，例如：

```text
auth      -> Auth VPS      -> Auth Cloud Run
tenant    -> Tenant VPS    -> Tenant Cloud Run
projects  -> Projects VPS  -> Projects Cloud Run
webhooks  -> Webhook VPS   -> Webhook Cloud Run
worker    -> Queue/Worker  -> Cloud Run Job 或独立 Worker
```

服务键、路径、超时、重试和幂等规则必须来自该业务域的交付清单，不允许由 Gateway 代码隐式猜测。

故障转移策略必须区分请求类型：GET/HEAD 等幂等请求可以在网络错误、超时或 5xx 时切换；写入类请求必须要求幂等键或由业务服务保证去重，不能对账单和支付请求进行无条件重试。

Gateway 配置至少包括：

```text
PORTAL_DOMAIN
API_DOMAIN
ACCOUNTS_UPSTREAM
BILLING_UPSTREAM
CONTENT_UPSTREAM
ACCOUNTS_FALLBACK_UPSTREAM
BILLING_FALLBACK_UPSTREAM
CONTENT_FALLBACK_UPSTREAM
TIMEOUT_MS
JWT_VERIFY_SECRET
```

Cloud Run 部署完成后，编排器读取真实 URL，再生成当前环境 upstream map。不能把可能变化的 Cloud Run URL 永久写死在 Vault 或生产 `wrangler.toml` 中。

### Portal

Portal 必须先通过以下决策：

- 如果可以稳定生成静态 `out`：使用 Cloudflare Pages；
- 如果依赖 Next.js standalone、动态 API route 或服务端渲染：使用 Cloud Run；
- 如果使用 Pages Functions/其他适配器：必须单独验证构建、运行时变量和路由合同。

Portal 的 `NEXT_PUBLIC_*` 配置在构建阶段注入，不能把私密数据库凭据打包进前端产物。

---

### Edge Gateway 定位：轻量级 API Gateway 与应用层流量调度

Cloudflare Worker 运行的 `edge-gateway` 定义为：

> **边缘级轻量 API Gateway + 应用层流量调度/故障转移层**。

它不是完整的 Kong 或 APISIX，也不是传统 DNS GTM；它是在请求到达 Cloudflare Edge 后，基于 HTTP 请求执行的 L7 路由和策略层。

```text
Cloudflare DNS
      ↓
Cloudflare Pages / CDN
      ↓
Cloudflare Worker edge-gateway
      ├── VPS 主服务
      └── Cloud Run fallback 服务
```

| 能力 | `edge-gateway` | Cloudflare GTM/Load Balancing | Kong / APISIX |
|---|---|---|---|
| 全球边缘执行 | 强 | 强 | 通常需要自建节点 |
| API 路由 | 支持 | 较弱 | 强 |
| JWT/JWKS、CORS、Header 改写 | 可实现 | 通常不负责 | 强 |
| VPS/Cloud Run 主备切换 | 可实现 | 支持健康检查和流量调度 | 需要插件或上层系统 |
| 限流与配额 | 需实现策略 | 基础能力 | 完整插件体系 |
| 服务发现与管理后台 | 需通过配置/KV实现 | 有控制台 | 完整 Admin API/UI |
| 东西向服务治理 | 不适合 | 不适合 | 适合 |
| 运维成本 | 极低 | 中等 | 较高 |

当前 Micro SaaS 规模下，`edge-gateway` 负责：

- 服务级路径路由；
- JWT/JWKS 验签；
- CORS 和 Header 处理；
- 超时、基础限流和请求追踪；
- VPS 主服务到 Cloud Run fallback 的应用层切换；
- 对写请求执行幂等键和重试边界控制。

它不负责长时间任务、大文件持久化、复杂服务注册、完整 API 产品目录或高复杂度东西向治理。服务数量、多租户配额、mTLS、gRPC、动态发现和插件策略显著增长后，再评估 Kong/APISIX。

因此平台文档统一称其为 **Edge API Gateway / Application Traffic Steering Layer**，不将其宣称为完整 GTM、Kong 或 APISIX 的替代品。
