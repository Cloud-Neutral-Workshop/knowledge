# 运维复盘与故障排查 SOP：UAT 环境控制台出口带宽与磁盘 I/O 突发 Spike 排查实录

- **故障目标节点**：`console-uat.onwalk.net`（UAT 环境核心控制台）
- **故障触发时间**：2026 年某日 07:30:00 – 08:00:00 (UTC+8)
- **文档编号**：`ops-runbook-20260809-uat-audit-log-io-spike`
- **关联 PR**：[ai-workspace-services/accounts#57](https://github.com/ai-workspace-services/accounts/pull/57)

---

## 一、 现象与指标跳变汇总

在 07:30 前后，监控系统连续弹出 `CRITICAL` / `WARNING` 级别告警。网卡带宽与磁盘 I/O 同时发生数量级突变：

| 监控指标 | 正常基线 | 异常峰值 | 告警级别 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| **网卡 eth0 出口带宽** | ~15 Mbps | **850 Mbps** | `WARNING` | 陡增约 57 倍 |
| **磁盘 /dev/sda I/O %util** | < 20% | **98.4%** | `CRITICAL` | 磁盘瓶颈接近满载 (100%) |
| **磁盘写延迟 (await)** | ~2 ms | **450 ms** | `CRITICAL` | 响应时间严重受阻 |
| **磁盘读吞吐 (Read)** | 低 | **120 MB/s** | `CRITICAL` | 频繁全表裸盘读取 |
| **磁盘写吞吐 (Write)** | 低 | **95 MB/s** | `CRITICAL` | 缓存刷盘与备份叠加 |

---

## 二、 四大 MCP 协议观测宇宙架构

利用 **MCP (Model Context Protocol)** 协议，AI Agent 充当“排障总指挥”，通过四大专职 MCP 工具链并行下钻，构建闭环证据链：

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI Agent (LLM 排障大脑)                       │
│     理解问题 → 规划 Tool Calls → 交叉验证 → 输出根因与方案         │
└──────┬──────────┬──────────┬──────────┬──────────────┬──────────┘
       │          │          │          │              │
       ▼          ▼          ▼          ▼              ▼
┌────────────┐┌────────────┐┌────────────┐┌────────────┐┌──────────────┐
│VictoriaMetrics││VictoriaLogs ││VictoriaTraces││  Grafana   ││  MCP 协议    │
│  MCP :8430 ││  MCP :9430 ││  MCP :4320 ││  MCP :3001 ││ (JSON-RPC)   │
│  指标下钻  ││  日志检索  ││  链路追踪  ││  告警联动  ││  统一编排    │
└────────────┘└────────────┘└────────────┘└────────────┘└──────────────┘
       │          │          │          │
       ▼          ▼          ▼          ▼
   MetricsQL    LogsQL    TraceQL/OTLP AlertManager
```

---

## 三、 四步联动排障实录

### Step 1 · VictoriaMetrics MCP —— 用指标锁定“爆炸半径”
AI Agent 通过 VictoriaMetrics MCP 执行 MetricsQL 查询，将模糊的“卡顿”量化为具体网卡与进程：

```promql
# 1. 确认网卡与吞吐方向
sum(rate(node_network_receive_bytes_total{instance="console-uat.onwalk.net"}[5m])) by (device)
+ sum(rate(node_network_transmit_bytes_total{instance="console-uat.onwalk.net"}[5m])) by (device)

# 2. 磁盘 I/O 读写与利用率下钻
rate(node_disk_read_bytes_total{instance="console-uat.onwalk.net"}[5m])
rate(node_disk_written_bytes_total{instance="console-uat.onwalk.net"}[5m])
rate(node_disk_io_time_seconds_total{instance="console-uat.onwalk.net"}[5m])

# 3. 进程级归因（谁在读写磁盘与发包）
topk(5, rate(namedprocess_namegroup_read_bytes_total{instance="console-uat.onwalk.net"}[5m]))
topk(5, rate(namedprocess_namegroup_write_bytes_total{instance="console-uat.onwalk.net"}[5m]))
```

- **下钻结论**：
  - `eth0` 流量从 15 Mbps 陡增至 850 Mbps；`/dev/sda` 读 120 MB/s、写 95 MB/s、`%util` 98.4%。
  - **进程锁定**：`postgres` 进程贡献了 82% 的磁盘读流量；`vector` 管道与备份进程贡献了 75% 的磁盘写流量 + 85% 的网络发包。

---

### Step 2 · VictoriaLogs MCP —— 用日志还原“案发现场”
AI Agent 使用 VictoriaLogs MCP 按时间窗对齐检索 LogsQL：

```logsql
_stream:{instance="console-uat.onwalk.net"} AND (level:error OR status:>=500 OR "backup" OR "export")
```

- **关键日志捕获**：
  1. `07:30:05` `[scheduler-service]`：触发定时任务 `Triggered automated cron job: UAT Data Mirror & Audit Log Snapshot Export to remote storage.`
  2. `07:35:12` `[caddy]`：大文件未压缩导出请求 `High volume HTTP GET stream on /v1/telemetry/snapshots/export?table=audit_logs from IP 10.0.4.15 (Payload size: 12.4 GB).`
- **结论**：未压缩的大文件导出接口 `/v1/telemetry/snapshots/export` 命中 12.4 GB 裸数据导出。

---

### Step 3 · VictoriaTraces MCP —— 用分布式链路找出“时间黑洞”
AI Agent 调取 Trace ID `e8a9d102c4b5768f` 的 OTLP 链路进行 Span 分析：

```
Trace ID: e8a9d102c4b5768f
GET /v1/telemetry/snapshots/export  —— Total Duration: 18,450 ms
  ├── caddy.reverse_proxy             ──> 12 ms      (网关转发)
  ├── console-service.handle_export   ──> 45 ms      (应用层逻辑)
  ├── postgres.query                  ──> 14,200 ms  ⚠️ 占 77% (SELECT * FROM audit_logs WHERE created_at > ...)
  │     [Seq Scan Full Table Read]                   ⚠️ 全表顺序扫描！
  └── stream.write_to_disk & push     ──> 4,193 ms   ⚠️ 阻塞式磁盘 I/O
```

- **结论**：18.45s 请求总时长中，PostgreSQL 占了 14.2s (77%)，根因在于 `Seq Scan Full Table Read`（全表顺序扫描 12.4 GB 的 `audit_logs` 表）。

---

### Step 4 · Grafana MCP —— 告警与大盘交叉验证
使用 Grafana MCP 确认证据链闭环：
- `AlertManager` 告警生效：`NodeHighDiskUtilization` (CRITICAL) 和 `NodeNetworkTransmitSpike` (WARNING)。
- Dashboard `host-metrics-uat` 面板显示：写延迟 (await) 由 2ms 攀升至 450ms，无误报。

---

## 四、 根因分析与“放大链”模型

```
07:30:00 UAT 定时快照同步任务触发
       │
       ▼
离线拉取 12.4 GB 未压缩审计日志快照 GET /v1/telemetry/snapshots/export
       │
       ├─────────────────────────────────┐
       ▼                                 ▼
① 网络流量暴涨                     ② PostgreSQL 响应快照查询
  850 Mbps 出口带宽                   audit_logs.created_at 缺失索引
       │                                 │
       │                                 ▼
       │                          全表顺序扫描 Seq Scan（12 GB 裸盘读取）
       │                                 │
       │                                 ▼
       │                          磁盘读 120 MB/s + Vector/备份写 95 MB/s
       │                                 │
       └────────────────┬────────────────┘
                        ▼
               /dev/sda I/O %util 饱和 98.4%
               写延迟 2ms → 450ms
```

**一句话根因**：UAT 环境定时快照任务拉取 12.4 GB 未压缩审计日志，因 `audit_logs` 表在 `created_at` 字段上**缺失索引**，迫使 PostgreSQL 对磁盘执行全表顺序扫描 (Seq Scan)；同时叠加 Vector 磁盘缓冲与备份写盘，引发网络带宽与磁盘 I/O 联动爆满。

---

## 五、 自动化修复与补丁落地

### 5.1 数据库索引与 Retention 优化（PR [accounts#57](https://github.com/ai-workspace-services/accounts/pull/57)）
在 `accounts` 服务中加入 DDL 迁移文件 `sql/20260809_audit_logs_optimization.sql`：

```sql
-- 1. 创建并发 B-Tree 索引（消除全表扫描，无锁执行）
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_logs_created_at
ON public.audit_logs (created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_logs_action_created_at
ON public.audit_logs (action, created_at DESC);

-- 2. 批次清理过期日志存储过程（防止单次 DELETE 锁表与磁盘暴胀）
CREATE OR REPLACE FUNCTION public.clean_expired_audit_logs(retention_days INT DEFAULT 30, batch_size INT DEFAULT 5000)
RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
  deleted_count INT := 0;
  total_deleted INT := 0;
  cutoff_time TIMESTAMPTZ;
BEGIN
  cutoff_time := now() - (retention_days || ' days')::INTERVAL;
  LOOP
    DELETE FROM public.audit_logs
    WHERE uuid IN (
      SELECT uuid FROM public.audit_logs
      WHERE created_at < cutoff_time
      LIMIT batch_size
    );
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    total_deleted := total_deleted + deleted_count;
    EXIT WHEN deleted_count = 0;
  END LOOP;
  RETURN total_deleted;
END;
$$;
```

### 5.2 网关流式压缩与限流配置
在网关配置流式 gzip/zstd 压缩与速率限制：

```caddy
handle_path /v1/telemetry/snapshots/export {
    encode gzip zstd
    rate_limit {
        zone export_limit {
            key static
            events 10
            window 1m
        }
    }
    reverse_proxy console-backend:8080
}
```

### 5.3 错峰调度与 Buffer 限制
- 将全量数据快照同步任务调整至低峰期 `03:00`。
- 限制 Vector 磁盘缓冲区配额为 `512 MiB` 并启用异步刷盘。

---

## 六、 复盘效果校验

修补方案落地后，在相同快照导出场景下测试复核：

| 校验指标 | 修复前 | 修复后 | 改善幅度 |
| :--- | :--- | :--- | :--- |
| **查询模式** | Seq Scan (全表扫描) | Index Scan (B-tree 索引) | 扫描页数下降 > 99% |
| **出口带宽** | 850 Mbps | 15 Mbps | 带宽占用下降 98% |
| **磁盘 I/O %util** | 98.4% (CRITICAL) | 14.2% (Normal) | 彻底消除 I/O 瓶颈 |
| **磁盘写延迟 (await)** | 450 ms | 1.8 ms | 延迟恢复基线水平 |
