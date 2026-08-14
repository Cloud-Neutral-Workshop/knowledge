# 全栈三层立体容灾矩阵架构设计与工程落地

> **InfoQ 架构师深度专栏**  
> **目标系统**：`ai-workspace-service` 与云中立基础设施矩阵  
> **技术栈**：Cloudflare Pages/Workers + Docker Compose / k3s / Sealos + GCP Cloud Run + 自建 PostgreSQL / Supabase Cloud  
> **架构核心**：**“自建稳态主导、云端零闲置兜底、全链路立体降级”** —— 构建具备 99.99% 企业级高可用且 TCO 仅需 $5/月的全栈容灾体系。

---

## 📌 一、 架构愿景与设计哲学

在现代分布式系统架构中，单一的基础设施形态往往难以兼顾**成本、自主可控性与高可用性**：
* **纯公有云架构**：面临昂贵且不可预测的出站流量（Egress）计费、数据库按量扩容费与商业 GTM 调度费；
* **纯单机/自建架构**：虽然硬件成本极低、保留全部数据库 C 扩展（如 `pgvector`、`pg_jieba`），但面临单点物理故障（SPOF）、机房掉电或网络抖动导致的业务中断。

本方案提出 **“全栈三层立体容灾矩阵” (Full-Stack 3-Tier Fallback Matrix)**：
1. **主生产环境（自建稳态）**：由自建单机 VPS（Docker Compose）或多机轻量集群（Sealos / k3s）承载 99% 的日常稳态流量，享受 **0 冷启动、0 流量计费、原生性能与数据主权**；
2. **备用灾备环境（云端无服务器）**：由 Cloudflare Pages、GCP Cloud Run（缩容至 0 实例）与 Supabase Cloud 组成全套云端降落伞，**平时保持 $0 闲置成本**；
3. **边缘智能中枢**：由 `edge-gateway.svc.plus`（Cloudflare Worker）进行全链路毫秒级健康探测与秒级故障切流。

---

## 🏛️ 二、 全栈三层立体容灾矩阵全景图

```mermaid
graph TD
    Client[用户端浏览器 / 控制台] --> Edge[edge-gateway: Cloudflare Worker<br/>⚡ 智能流量调度与全链路健康探测]

    subgraph 【第一层: 前端与静态资源层】
        Edge -->|主链路 (99% 流量)| Front_Primary[主: VPS Caddy / Nginx 静态托管<br/>console.svc.plus]
        Edge -.->|主节点不可达时秒级降级| Front_Fallback[备: Cloudflare Pages / Vercel<br/>全球边缘 CDN 0 延迟秒开 ($0)]
    end

    subgraph 【第二层: 业务计算与微服务层】
        Edge -->|主链路 (99% 流量)| App_Primary[主: VPS Docker Compose / k3s / Sealos<br/>Go microservices (accounts / billing)]
        Edge -.->|主节点超时/5xx 秒级降级| App_Fallback[备: GCP Cloud Run (缩容至 0 实例)<br/>平时 💰 $0/月，故障时 ~200ms 拉起]
    end

    subgraph 【第三层: 数据库与状态持久层】
        App_Primary -->|主写入/主读取 (直连)| DB_Primary[(主: 本地 postgresql.svc.plus<br/>支持 pgvector / pg_jieba 全量扩展)]
        App_Fallback -->|故障时备用读写 (Supavisor 6543)| DB_Fallback[(备: Supabase Cloud PostgreSQL<br/>云端全托管 / 每日自动备份)]
        DB_Primary -.->|PG 逻辑复制 (wal_level=logical) 实时增量同步| DB_Fallback
    end
```

---

## 📊 三、 三层容灾降级规范表

| 架构层级 | 主生产环境 (Primary - 自建稳态) | 备用灾备环境 (Fallback - 云端 Serverless) | 容灾切换触发机制 | 数据一致性与用户体验 |
| :--- | :--- | :--- | :--- | :--- |
| **第一层：前端层** | **VPS Caddy 静态托管** (`console.svc.plus`) | **Cloudflare Pages / Vercel** (全球 CDN 静态托管) | 边缘网关检测到主节点 Web 服务端口断连或 TLS 异常 | 用户端毫秒级重定向至 CDN 镜像，界面秒开无感知 |
| **第二层：计算层** | **Docker Compose / k3s / Sealos Go 微服务** | **GCP Cloud Run** (缩容至 0 实例容器) | `edge-gateway` 探测到主节点 2.5s 超时、网络拒绝或返回 `5xx` | **单次请求内透明重试降级**，响应头注入 `X-Upstream-Route: cloud-run-fallback` |
| **第三层：数据层** | **自建 `postgresql.svc.plus`** (完整本地扩展支持) | **Supabase Cloud PostgreSQL** (托管实例) | 主机房故障切流至 Cloud Run 后，直接连接 Supabase 备库 | 基于 PG 逻辑复制保持毫秒级增量同步，切换后零数据丢失 |

---

## 🛠️ 四、 主生产环境的多形态部署支持

主环境可根据业务规模灵活选择 **单机极简** 或 **多机集群** 形态，对外接口与容灾标准完全统一：

### 1. 单机极简形态 (Docker Compose + Caddy)
* **适用规模**：单台 2C4G 或 4C8G VPS（如 Contabo / 阿里云），月租约 $5~$10。
* **技术拓扑**：
  * **Caddy**：处理自动 HTTPS 证书、静态页面缓存及反向代理；
  * **Docker Compose**：启动 `accounts`, `billing-service`, `content-service` 等 Go 容器；
  * **PostgreSQL**：本地容器运行 `postgresql.svc.plus`，挂载本地 NVMe 卷。
* **特点**：极简免维护，整机内存消耗小于 1.5GB，单机可轻松承载 500~1,500 QPS。

### 2. 多机高可用形态 (Sealos / k3s 轻量级集群)
* **适用规模**：2~3 台跨地域 VPS 组网（如东京 + 新加坡 + 法兰克福）。
* **技术拓扑**：
  * 使用 **Sealos**（`sealos run labring/k8s:v1.27.0`）一键拉起轻量级高可用 Kubernetes 集群；
  * 各微服务以 Deployment (多副本 + HPA) 部署，配合 Sealos Ingress 暴露流量；
* **特点**：单台 VPS 硬件损坏时容器自动在集群内漂移自愈；若遭遇跨地域全网中断，则触发全局 Cloud Run 降级。

---

## 🔄 五、 数据层 (DB) 实时同步与故障接管设计

数据库状态一致性是全栈立体容灾的核心命脉。本架构采用 **“本地为主库、云端为热备”** 的增量同步机制：

```mermaid
graph LR
    subgraph 稳态工作流 (99% 时间)
        LocalApp[VPS Go 业务微服务] -->|读写本地| LocalDB[(主库: VPS postgresql.svc.plus<br/>wal_level = logical)]
        LocalDB -->|PG 逻辑复制 pgoutput (毫秒级)| SupaDB[(热备: Supabase Cloud PostgreSQL)]
    end

    subgraph 容灾工作流 (VPS 宕机故障期间)
        CloudRun[GCP Cloud Run 弹性实例] -->|接管读写 (Supavisor 6543)| SupaDB
    end
```

### 1. 开启本地 PostgreSQL 逻辑复制 (Publisher)
在自建 `postgresql.svc.plus` 的 `postgresql.conf` 中配置：
```ini
wal_level = logical
max_wal_senders = 10
max_replication_slots = 10
```
在主库创建发布端：
```sql
CREATE PUBLICATION pub_ai_workspace FOR ALL TABLES;
```

### 2. 在 Supabase Cloud 创建订阅端 (Subscriber)
在 Supabase 控制台执行订阅指令，建立安全 TLS 逻辑同步通道：
```sql
CREATE SUBSCRIPTION sub_ai_workspace
  CONNECTION 'host=vps-db.svc.plus port=5443 dbname=postgres user=replicator password=xxx sslmode=require'
  PUBLICATION pub_ai_workspace;
```

### 3. 故障切换与无脑裂保障
* 当主节点宕机时，`edge-gateway.svc.plus` 将流量切至 GCP Cloud Run；
* Cloud Run 环境变量配置指向 Supabase 连接池：
  `DATABASE_URL=postgres://postgres.[REF]:[PWD]@aws-0-[REGION].pooler.supabase.com:6543/postgres`
* 业务在云端继续安全读写，数据差异维持在秒级以内。

---

## 🚀 六、 边缘智能网关 (`edge-gateway.svc.plus`) 调度机制

部署在 Cloudflare 全球边缘的轻量级网关，负责全链路健康裁决与秒级熔断：

1. **深度健康探测 (Deep Health Check)**：
   - 定期对主节点 `/api/v1/health` 进行探针探测，该接口同时校验 **Go API 运行状态 + 本地 DB `SELECT 1` 联通性**；
   - 只有当整个主栈均处于健康状态时，才视为可用。
2. **请求级即时重试降级**：
   - 客户端请求在网关处优先打往主 VPS（2.5 秒快速熔断）；
   - 一旦遇到网络超时、连接断开或 `HTTP 5xx`，网关在**单次请求生命周期内**毫秒级透明改发 GCP Cloud Run，客户端完全无感知。

---

## 💰 七、 全栈 TCO 成本与可用性测算

| 运行场景 | 主节点状态 | 云端备用状态 | 月度综合总成本 | 可用性 (SLA) |
| :--- | :--- | :--- | :--- | :--- |
| **日常平稳稳态 (99% 时间)** | VPS 全载运行 ($5/月) | Cloud Run 0 实例 ($0) + Supabase ($0) + CF ($0) | **~$5.00 / 月**<br>*(约 35 元人民币)* | **99.9%** (0 冷启动，极速响应) |
| **机房掉电 / VPS 宕机灾备** | 故障下线 | Cloud Run 自动拉起 + Supabase 接管 (~$0.50) | **~$5.50 / 月** | **99.99%** (业务 0 中断) |
| **流量暴增 10 倍尖峰** | VPS 满载吞吐 | 超额流量弹性溢出至 Cloud Run 吸收 | 按秒计费微量增长 | **系统永远不崩** |

---

## 📋 八、 生产落地 Checklist

- [ ] **主库逻辑复制配置**：本地 `postgresql.svc.plus` 开启 `wal_level = logical`，并在 Supabase 端配置好安全订阅连接。
- [ ] **Go 服务连接池收敛**：确保 Go 服务在 Cloud Run 运行时连接 Supabase 的 **Supavisor 端口 (6543)**，设置 `SetMaxOpenConns(5)` 避免连接打爆。
- [ ] **深度健康探针就绪**：主节点 Go 服务实现 `/api/v1/health` 接口，联动探测本地数据库存活。
- [ ] **网关双上游注入**：在 `edge-gateway.svc.plus` 中通过 `vault.svc.plus` 注入 `PRIMARY_UPSTREAM` (VPS) 与 `FALLBACK_UPSTREAM` (Cloud Run)。
- [ ] **前端 CDN 镜像同步**：GitHub Actions 构建时，同时将静态产物推送到 VPS 与 Cloudflare Pages 备用源。
