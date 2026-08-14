# 控制面混合云弹性容灾与零成本流量调度架构实践

> **InfoQ 架构师深度专栏**  
> **适用业务**：`ai-workspace-service`（控制面）与基础设施服务  
> **技术矩阵**：Cloudflare Pages + Cloudflare Workers + GCP Cloud Run + Supabase + VPS (Docker Compose)  
> **核心主张**：精益工程、平战结合、彻底规避商业 GTM 与云厂商隐藏收费陷阱，构建从 $0 起步到顺畅承载数万日活的高可用双轨架构。

---

## 📌 一、 导读与架构背景

在构建 AI SaaS 及微服务系统时，开发者往往面临严峻的架构与成本抉择：
* **全上云与商业 SaaS**：遭遇细粒度按量计费陷阱（出站流量费、数据库按量扩容费、商业 GTM 调度费），账单不可控；
* **完全自建单机 VPS**：硬件成本低，但面临单点故障（SPOF）、运维繁重，且遇突发流量极易雪崩。

本实践立足于 **“控制面（Control Plane）与数据面（Data Plane）深度解耦”** 的核心洞察，系统性阐述如何利用现代 Serverless 的 **Scale-to-0（缩容至 0）** 特性，将 $5 的常驻 VPS 与云端 Serverless 融合成一套 **“平时不花多余钱，战时秒级弹性抗压，故障秒级透明自愈”** 的现代化混合架构。

---

## 🎯 二、 核心洞察：控制面与数据面的负载分水岭

在评估是否能够以极低成本（甚至 $0）支撑数万日活（DAU）时，必须明确业务的负载属性：

```mermaid
graph LR
    subgraph 控制面 (ai-workspace-service)
        User[用户] -->|1. 登录/鉴权/查权益 (日均 1~2次)| CP[控制面 API: accounts / billing]
        CP -->|纯元数据读写 < 100MB| DB[(Supabase Free / Postgres)]
    end

    subgraph 数据面 (独立承载)
        User -.->|2. 高频 AI 聊天/向量检索/文件流 (高频大吞吐)| DP[独立数据面: Agent/LLM/Gateway]
    end
```

| 维度 | 数据面 (Data Plane) | 控制面 (Control Plane - `ai-workspace-service`) |
| :--- | :--- | :--- |
| **业务内容** | 大模型流式推理、向量检索 (`pgvector`)、文档切片解析 | 用户登录鉴权 (`accounts`)、Stripe 订阅 (`billing`)、工作区元数据 |
| **请求频率** | 高频（单用户日均 30~50+ 次交互） | **极低频**（单用户日均仅 1~2 次打开工作区交互） |
| **存储特征** | 大体积（数 GB ~ 数十 GB 向量与聊天记录） | **微量元数据**（5 万用户纯关系型数据通常 `< 100 MB`） |
| **免费池容量** | 极易突破 Free 额度 | **完美落在 Cloud Run 200万次 / Supabase 500MB 免费池内** |

---

## 🏛️ 三、 双轨弹性容灾架构全景拓扑

```mermaid
graph TD
    User[全球终端用户] --> Ingress[Cloudflare 全球边缘网络]

    subgraph 1. 接入与智能路由层 (Edge Tier)
        Ingress -->|静态资源请求 (HTML/JS/CSS)| CFP[Cloudflare Pages / Vercel<br/>💰 $0/月 无限带宽 CDN]
        Ingress -->|动态 API 请求 (/api/*)| CFW{CF Worker 边缘网关 / 前端拦截器<br/>• 0ms 冷启动 / JWT 验签<br/>• 零成本实时故障转移}
    end

    subgraph 2. 双轨计算层 (Dual Compute Tier)
        CFW -->|常态主路由 (99% 平稳流量)| VPS[主节点: 廉价 VPS ($5/月)<br/>• Docker Compose 部署 Go 微服务<br/>• 0 冷启动、无公网流量计费焦虑]
        CFW -->|故障降级 / 突发溢出 (秒级激活)| CloudRun[弹性节点: GCP Cloud Run<br/>• Go 原生容器 (平时 0 实例，💰 $0/月)<br/>• 探测到故障时 ~200ms 自动拉起]
    end

    subgraph 3. 统一数据状态层 (State & DB Tier)
        VPS -->|Supavisor 连接池 6543| SupaDB[(Supabase Cloud PostgreSQL<br/>• 唯一真实数据源 Single Source of Truth<br/>• 500MB 元数据永久免费 / 免运维备份)]
        CloudRun -->|Supavisor 连接池 6543| SupaDB
    end

    subgraph 4. 统一可观测性 (Observability Tier)
        VPS -.->|OTLP gRPC 4317| Obs[observability.svc.plus / Grafana Cloud]
        CloudRun -.->|OTLP gRPC 4317| Obs
    end
```

---

## ⚙️ 四、 核心组件技术选型与深度权衡

### 1. 计算层：为什么选择 GCP Cloud Run 而非 Cloudflare Workers？
* **代码零重构**：`ai-workspace-service` 采用标准的 Go 语言微服务（包含现成 `Dockerfile`）。GCP Cloud Run 提供 100% 容器原生支持，**0 行代码改动**；而 Cloudflare Workers 基于 V8 Isolate 沙箱，无法原生运行 Go Linux 二进制。
* **极速冷启动**：Go 静态编译二进制极小（~20MB），在 Cloud Run 上的冷启动时间仅为 **150ms ~ 300ms**，控制面用户完全无感知。
* **原生数据库驱动**：标准 `database/sql` 与 `pgx` 驱动走 TCP 协议，稳定可靠。

### 2. 避免云厂商的隐藏收费刺客（Gotchas）
* **GCP 出站流量 (Egress)**：每月仅 1GB 免费额度，超出后按 ~$0.12/GB 计费。控制面 API 必须开启 Gzip/Brotli 压缩，保持纯 JSON 交互。
* **GCP 镜像存储 (Artifact Registry)**：配置生命周期策略，**仅保留最新 3 个 Docker Tag**，避免产生冗余存储费。
* **保持 `min-instances = 0`**：平时不常驻开机，杜绝闲置计算计费。

---

## 🚀 五、 告别昂贵商业 GTM：三大 $0 零成本流量调度实现

传统的商业级 GTM（如 AWS Route53 Traffic Flow $50/月、Cloudflare Load Balancing $10+/月）费用高昂。本架构通过 **代码级与客户端重试** 实现 $0 流量调度：

### 方案 A：Cloudflare Worker 内部秒级 `try-catch` 容灾（最推荐 🌟）
直接利用普通的免费 Worker，在单次请求内完成实时熔断与重试，**完全不依赖任何付费 GTM 插件**：

```javascript
// Cloudflare Worker: 零成本毫秒级故障转移与备用分流
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // 仅拦截 /api/ 动态控制面请求
    if (url.pathname.startsWith("/api/")) {
      const vpsOrigin = "https://vps-api.svc.plus";
      const cloudRunOrigin = "https://api-service-uc.a.run.app";

      const vpsUrl = new URL(url.pathname + url.search, vpsOrigin);

      try {
        // 1. 设置 2.5 秒快速熔断超时
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 2500);

        const response = await fetch(vpsUrl.toString(), {
          method: request.method,
          headers: request.headers,
          body: request.body,
          signal: controller.signal,
        });
        clearTimeout(timeoutId);

        // 如果 VPS 节点健康且返回正常状态码，直接返回
        if (response.status < 500) {
          return response;
        }
        throw new Error(`VPS upstream returned status ${response.status}`);
      } catch (err) {
        // 2. VPS 故障、超时或宕机，透明重试并无缝降级至 GCP Cloud Run
        console.warn("[Failover] VPS unreachable, routing to Cloud Run:", err.message);
        const cloudRunUrl = new URL(url.pathname + url.search, cloudRunOrigin);

        return await fetch(cloudRunUrl.toString(), {
          method: request.method,
          headers: request.headers,
          body: request.body,
        });
      }
    }

    return fetch(request);
  },
};
```

### 方案 B：前端客户端 Axios / Fetch 智能拦截器（绝对 $0）
将容灾能力下推到前端浏览器，完全脱离任何服务端调度依赖：

```typescript
// portal/src/lib/api-client.ts
import axios from 'axios';

const PRIMARY_API = 'https://api-vps.svc.plus';
const FALLBACK_API = 'https://api-cloudrun.a.run.app';

export const apiClient = axios.create({
  baseURL: PRIMARY_API,
  timeout: 3000,
});

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const config = error.config;
    if (!config._retry && (error.code === 'ECONNABORTED' || !error.response || error.response.status >= 500)) {
      config._retry = true;
      config.baseURL = FALLBACK_API;
      sessionStorage.setItem('use_fallback_api', 'true');
      return apiClient(config);
    }
    return Promise.reject(error);
  }
);
```

---

## 💰 六、 流量规模与真实成本测算模型

| 业务运行阶段 | 规模与流量 | 实际工作组件 | 月度总支出 | 架构表现 |
| :--- | :--- | :--- | :--- | :--- |
| **阶段 1：冷启动 / MVP 期** | 500 ~ 2,000 DAU | • CF Pages ($0)<br>• Cloud Run ($0 免费池)<br>• Supabase Free ($0) | **$0.00 / 月** | 零成本跑通业务，无服务器维护负担。 |
| **阶段 2：常态稳态运行 (99% 时间)** | 20,000 ~ 50,000 DAU | • CF Pages ($0)<br>• 主节点 VPS ($5/月)<br>• Cloud Run (0 实例休眠 $0)<br>• Supabase Free ($0) | **~$5.00 / 月**<br>*(约 35 元人民币)* | **极速 0 冷启动**，VPS 消化稳态流量，无流量超额扣费。 |
| **阶段 3：VPS 宕机或突发流量** | 流量暴涨 10 倍，或 VPS 意外离线 | • CF Pages ($0)<br>• CF Worker 秒级分流 ($0)<br>• Cloud Run 弹性拉起 (~$0.50)<br>• Supabase ($0) | **~$5.50 / 月** | **SLA 达到 99.99%**，业务完全不中断，用户端零感知。 |

---

## 📋 七、 生产落地实施 Checklist

- [ ] **数据库连接池收敛**：确保 Go 服务连接 Supabase 的 **Supavisor 端口 (6543)**，并设置 `db.SetMaxOpenConns(5)`，防止 Cloud Run 水平扩展打爆连接。
- [ ] **单一真实数据源**：VPS 与 Cloud Run 均连接相同的 Supabase 数据库实例，绝不在本地保存异构状态，彻底防止数据脑裂。
- [ ] **GCP 预算预警机制**：在 GCP Console 设置一条 **$1 美元消费预警**，防范出站流量与镜像存储产生意外开销。
- [ ] **前端 Token 缓存**：控制台前端对有效 JWT 进行 localStorage 缓存（有效时间 1~2 小时），将控制面日均访问请求严格控制在 10 万次以内。
- [ ] **可观测性统一上报**：VPS 与 Cloud Run 注入统一的 `OTEL_EXPORTER_OTLP_ENDPOINT`，确保跨环境 Trace 追踪完全贯通。
