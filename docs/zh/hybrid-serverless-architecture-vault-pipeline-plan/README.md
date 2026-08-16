# VPS + Serverless 混合部署极简成本架构规划与工程落地指南

这是面向未来各类 Micro SaaS 的弹性架构基础规范。`ai-workspace-service` 是第一套参考实现；新增 SaaS 复用平台层、身份层、观测层、发布层和成本治理，不重新设计整套部署体系。

## 阅读顺序

1. [架构目标、总体架构与资源分层](./01-architecture-and-resources.md)
2. [统一身份与 Vault 三层路径](./02-identity-and-vault.md)
3. [运行时配置、制品与不可变发布](./03-runtime-and-artifacts.md)
4. [混合部署流水线与 Cloud Run 生命周期](./04-deployment-and-cloud-run.md)
5. [数据库、Edge Gateway、Portal 与域名合同](./05-database-gateway-and-portal.md)
6. [观测、备份、恢复与成本模型](./06-observability-backup-and-cost.md)
7. [Micro SaaS 接入、落地顺序与上线验收](./07-rollout-and-acceptance.md)

## 当前参考实现

- `console-uat.onwalk.net`：`2C4G`，运行 Caddy、Portal、Accounts、Billing、Content 和自建 PostgreSQL；
- `observability.svc.plus`：Grafana、VictoriaMetrics、VictoriaLogs、VictoriaTraces 及四个 MCP；
- MCP 保留：`observability-grafana`、`observability-logs`、`observability-metrics`、`observability-traces`；
- `observability-trace` 单数配置不存在；
- Grafana Metrics、Logs、Traces 数据源健康；MCP 当前 Codex 展示状态需以客户端 `codex mcp list` 为准。

### 当前参考实现：VPS 各类 SaaS 服务选择概览

下表用于新增 Micro SaaS 的第一轮资源选型。它描述的是“默认放在哪里”和“何时拆分”，不是把每个服务永久固定在某一种平台；最终档位必须根据实际 QPS、并发、数据库连接、磁盘增长和外部 API 延迟复核。

| SaaS 服务类型 | 当前参考服务 | 首选运行位置 | 最小运行资源 | 推荐资源 | 预估承载能力/拆分信号 |
|---|---|---|---|---|---|
| 静态 Portal、文档站、营销页 | Portal | Cloudflare Pages + CDN | 无常驻 VPS | Pages + Worker | 适合低成本发布；只有 SSR、长任务或私有网络依赖时回 VPS/Cloud Run |
| 认证、账户、租户、简单 CRUD | Accounts | 共享控制面 VPS，Cloud Run `min=0` 备用 | 共享 `2C4G` | 独立 `1C1G` 或共享 `4C8G` | 约 10–30 RPS 总 API；持续高峰、连接池或故障隔离要求上升时拆分 |
| 计量、账单、支付、Webhook | Billing | VPS 主承载 + Cloud Run 弹性副本 | `1C1G`/服务 | `2C2–4G`/服务 | 约 10–30 写请求/秒；出现重试、队列积压、Stripe 延迟或幂等压力时优先独立部署 |
| 内容、知识库、管理后台 API | Content | VPS；无状态读取可迁 Cloud Run | `0.5C512M` | `1C1–2G` | 约 10–30 RPS；索引构建、文件处理或内存缓存增长时拆分，数据库连接仍走 Pooler |
| 异步 Worker、定时任务、队列消费者 | 新 Micro SaaS Worker | Cloud Run Jobs/Service 或独立 VPS Worker | `0.5C512M` | `1C1–2G`，按队列扩容 | 以任务耗时、队列积压和并发执行数为准；不与同步 API 争抢连接池 |
| AI 推理、向量检索、长连接、文件处理 | 知识库/AI 扩展 | 独立 VPS/专用节点 + Cloud Run 辅助 | 独立资源池 | `4C8G+`，按 GPU/IO/带宽压测 | 不建议放进 `console-uat` 控制面；CPU、内存、磁盘或带宽持续超过 60–70% 即拆分 |
| 代理、Xray、长连接数据面 | Agent-proxy、Xray | 独立代理 VPS | `1–2C2G` | `2–4C4–8G`，SSD `40–200GB` | 主要受带宽、长连接、加密 CPU 和磁盘日志影响；不要与 PostgreSQL/观测平台长期合并 |
| PostgreSQL/业务状态 | 当前自建 PostgreSQL；目标 Supabase Cloud | Supabase Cloud；迁移期保留 VPS 回滚 | 托管或 VPS `2C4G` | Supabase 按套餐；自建建议 `4C8G+` | 以连接数、IOPS、存储和备份恢复窗口为准；迁移完成前禁止双写 |
| Metrics、Logs、Traces、Grafana | `observability.svc.plus` | 独立观测 VPS | `2C4G / 150GB SSD` | `4C8G / 300GB SSD` | 约 4–6 个节点、低至中等写入量；按日志/Trace 写入速率和磁盘保留期扩容 |

推荐的默认落地组合是：Portal 走 Pages，Accounts/Billing/Content 共享 `2C4G` 控制面 VPS，Cloud Run 保留 `min=0` 弹性副本；PostgreSQL 使用 Supabase Cloud Pooler；Agent-proxy 与 Observability 使用独立资源池。只有当某一类服务达到拆分信号，才单独升级资源或迁移运行位置。

### 数据库连接选择

运行时连接和迁移/备份连接必须分离：

| 场景 | 推荐连接 | Vault Key |
|---|---|---|
| VPS 日常运行 | Session pooler `5432`；IPv4-only 时最稳 | `DATABASE_SESSION_POOLER_URL` |
| Cloud Run 日常运行 | Session pooler；应用兼容事务池化时再用 Transaction pooler `6543` | `DATABASE_SESSION_POOLER_URL` / `DATABASE_TRANSACTION_POOLER_URL` |
| schema/DDL/`pg_dump` 迁移 | Direct connection；无 IPv6 时可用 Session pooler | `DATABASE_DIRECT_URL` |
| 备份恢复 | Direct 优先；IPv4-only 时使用 Session pooler | `DATABASE_DIRECT_URL` / `DATABASE_SESSION_POOLER_URL` |

统一存放在：

```text
kv/data/<env>/serverless/supabase
├── PROJECT_REF
├── DATABASE_SESSION_POOLER_URL
├── DATABASE_TRANSACTION_POOLER_URL  # 可选
└── DATABASE_DIRECT_URL               # migration/backup 专用
```

`DATABASE_DIRECT_URL` 不得注入普通业务运行时；运行时只读取按场景选择的 Pooler URL。
Transaction pooler 仅适用于已验证 prepared statement、session state 和连接池行为的
无状态服务；当前 Accounts/Billing 默认使用 Session pooler。

## 兼容入口

原始单文件版本仍保留在上级目录，作为历史引用和全文对照：

[hybrid-serverless-architecture-vault-pipeline-plan.md](../hybrid-serverless-architecture-vault-pipeline-plan.md)

拆分文件是后续维护的推荐入口；章节内容按原文顺序组织，新增的 Edge Gateway 定位说明位于第五章。
