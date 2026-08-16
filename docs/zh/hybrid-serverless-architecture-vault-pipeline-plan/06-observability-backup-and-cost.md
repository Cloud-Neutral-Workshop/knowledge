## 十一、健康检查、观测与验收

每个服务至少提供：

```text
/healthz
/readyz
```

部署验证包括：

1. 交付清单中声明的 VPS 主服务和 Cloud Run 备用服务均成功启动或处于可验证状态；
2. 数据库连接成功；
3. Gateway 能正确路由 accounts、billing、content；
4. JWT 验签成功且错误 Token 被拒绝；
5. CORS 和 OPTIONS 行为正确；
6. Portal 能访问当前环境 API；
7. 关键登录、账户、内容和账单接口通过；
8. Worker、VPS 和 Cloud Run 日志可查询；
9. 模拟 VPS 超时/5xx 时，幂等请求切换到对应 Cloud Run 服务；
10. VPS 恢复后流量可以回主，写入请求没有重复副作用。

### 观测架构约束

`observability.svc.plus` 可以继续部署在 VPS，作为平台级自建观测入口；Cloud Run、VPS 和 Worker 都必须上报统一的日志、指标和 Trace。观测写入失败不得阻断业务请求，远端 Agent 必须使用 HTTPS、认证和有界缓冲。

当前参考实现的只读观测基线：

| 项目 | 实测值 | 架构含义 |
|---|---:|---|
| Metrics 时序 | 约 22,451 条 | 当前 `xray` 约 19,301 条，占约 86%，需要治理高基数标签 |
| Logs | 过去 24 小时约 49 万条 | `2C4G` 观测节点可运行，但长期保留必须控制磁盘 |
| Traces 服务 | 3 个 | 当前覆盖 Accounts、Billing、Console；新增 Content 或其他 SaaS 必须补充 OTLP |
| Grafana 数据源 | Metrics、Logs、Traces 均健康 | 三个数据源保留；MCP 四项配置保留，但 `codex mcp list` 当前显示 `Unsupported` |

平台级 MCP 接口属于可复用能力，不应与某个业务服务绑定：

```text
observability-grafana
observability-logs
observability-metrics
observability-traces
```

MCP 配置合同如下：

| MCP | Endpoint | 当前 Codex 状态 | 处理原则 |
|---|---|---|---|
| `observability-grafana` | `https://observability.svc.plus/mcp/v1/grafana/mcp` | `Unsupported` | 保留，作为 Grafana 查询/面板能力入口 |
| `observability-logs` | `https://observability.svc.plus/mcp/v1/logs/mcp` | `Unsupported` | 保留，作为 VictoriaLogs 查询入口 |
| `observability-metrics` | `https://observability.svc.plus/mcp/v1/metrics/mcp` | `Unsupported` | 保留，作为 VictoriaMetrics 查询入口 |
| `observability-traces` | `https://observability.svc.plus/mcp/v1/traces/mcp` | `Unsupported` | 保留，作为 VictoriaTraces 查询入口 |

`Unsupported` 不得被流水线直接解释为服务宕机。验收时必须分别检查 MCP HTTP 初始化、鉴权、工具发现和实际只读查询；新 Micro SaaS 只需要注册服务名、环境、版本和数据源标签，即可复用现有 Grafana、Metrics、Logs、Traces 和 MCP 能力。

观测服务与业务 VPS 同机时，需要额外配置磁盘、Docker 日志、journald、Vector buffer 和恢复告警。观测平台不应成为 Vault、Worker 或业务服务的运行时强依赖。

### 统一观测字段

```text
OTEL_SERVICE_NAME
OTEL_ENVIRONMENT=<env>
OTEL_EXPORTER_OTLP_ENDPOINT
SOURCE_REPOSITORY
SOURCE_REVISION
IMAGE_TAG
IMAGE_DIGEST
DEPLOYMENT_ID
```

部署摘要不得输出 Secret、完整数据库 URL、JWT、API Token 或连接密码。

### 回滚

回滚以 Cloud Run revision 和镜像 digest 为准：

```text
记录当前 revision/digest
  ↓
发现 smoke test 或当前环境回归失败
  ↓
恢复上一个已验证 revision
  ↓
重新执行 Gateway 和关键 API 验证
```

数据库 migration 必须提供向前兼容策略。不能假设应用回滚会自动回滚数据库结构。

---

## 十二、Keepalive、备份与恢复

Supabase keepalive 只负责探测和记录状态，不替代备份。

必须分别定义：

- keepalive workflow；
- 数据库备份；
- 恢复演练；
- Schema 校验；
- 各环境 seed 重建；
- Vault KV 备份与恢复；
- Cloudflare Worker 配置恢复；
- Artifact digest 保留策略。

Keepalive 失败时应告警，不应把失败吞掉并报告成功。

---

## 十三、成本模型

| 资源 | 低闲置成本策略 | 成本风险 |
|---|---|---|
| Cloud Run | `min=0`、限制最大实例 | 请求、CPU、内存和网络超额 |
| Artifact Registry | 保留不可变发布窗口 | 镜像存储费用 |
| Cloudflare Worker | 控制请求量和日志量 | 超出免费请求额度 |
| Cloudflare Pages | 仅适合经过验证的静态产物 | 动态能力和构建限制 |
| Supabase | Pooler、容量和连接数控制 | Free 项目暂停、容量和额度限制 |
| Vault | 复用现有控制面 | 可用性、备份和运维成本 |
| GitHub Actions | 定时和并发控制 | Runner 时长、并发和缓存 |

必须设置：

- GCP Budget Alert；
- Artifact Registry retention；
- Cloud Run max instance；
- Cloudflare 用量告警；
- Supabase 容量/暂停监控；
- GitHub Actions concurrency；
- cleanup dry-run 和审批模式。

---
