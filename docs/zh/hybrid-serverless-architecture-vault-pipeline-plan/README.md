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

## 兼容入口

原始单文件版本仍保留在上级目录，作为历史引用和全文对照：

[hybrid-serverless-architecture-vault-pipeline-plan.md](../hybrid-serverless-architecture-vault-pipeline-plan.md)

拆分文件是后续维护的推荐入口；章节内容按原文顺序组织，新增的 Edge Gateway 定位说明位于第五章。
