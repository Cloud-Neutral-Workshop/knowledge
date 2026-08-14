# Full-Stack 3-Tier End-to-End Fallback Matrix Architecture and Engineering Practice

> **InfoQ Architect Deep Dive**  
> **Target System**: `ai-workspace-service` & Cloud-Neutral Infrastructure Matrix  
> **Technology Stack**: Cloudflare Pages/Workers + Docker Compose / k3s / Sealos + GCP Cloud Run + Self-Hosted PostgreSQL / Supabase Cloud  
> **Core Principle**: **"Self-hosted baseline primary, cloud serverless zero-idle-cost standby, full-stack 3-tier fallback"** — Achieving enterprise 99.99% availability with a baseline TCO of only $5/month.

---

## 📌 1. Architecture Vision & Philosophy

In modern distributed systems engineering, single infrastructure paradigms struggle to balance **cost, autonomy, and high availability**:
* **Pure Public Cloud**: Faces unpredictable, granular pay-as-you-go cost traps (egress network fees, database compute scaling, commercial GTM routing fees);
* **Pure Self-Hosted VPS**: Extremely cheap and retains full database extensions (e.g. `pgvector`, `pg_jieba`), but remains vulnerable to Single Points of Failure (SPOF), power outages, or network fiber cuts.

This document presents the **"Full-Stack 3-Tier End-to-End Fallback Matrix"**:
1. **Primary Production Environment (Self-Hosted Baseline)**: Single-node VPS (Docker Compose) or lightweight multi-node cluster (Sealos / k3s) handles 99% of steady-state traffic, enjoying **zero cold-start, zero egress cost, native speed, and data sovereignty**;
2. **Fallback Disaster Recovery Environment (Cloud Serverless)**: Cloudflare Pages, GCP Cloud Run (scaled to 0 instances), and Supabase Cloud form a full cloud backup parachute, **incurring $0 idle costs during normal operations**;
3. **Edge Intelligent Orchestrator**: `edge-gateway.svc.plus` (Cloudflare Worker) performs millisecond-level health probing and instant failover.

---

## 🏛️ 2. Full-Stack 3-Tier End-to-End Fallback Topology

```mermaid
graph TD
    Client[Client / Console Web] --> Edge[edge-gateway: Cloudflare Worker<br/>⚡ Intelligent Traffic Steering & Deep Health Probing]

    subgraph 【Tier 1: Frontend & Static Asset Layer】
        Edge -->|Primary Route (99% Traffic)| Front_Primary[Primary: VPS Caddy / Nginx Static Hosting<br/>console.svc.plus]
        Edge -.->|Instant Failover if Host Unreachable| Front_Fallback[Fallback: Cloudflare Pages / Vercel<br/>Global Edge CDN 0ms Delivery ($0)]
    end

    subgraph 【Tier 2: API Compute & Microservices Layer】
        Edge -->|Primary Route (99% Traffic)| App_Primary[Primary: VPS Docker Compose / k3s / Sealos<br/>Go microservices (accounts / billing)]
        Edge -.->|Failover on Timeout/5xx Error| App_Fallback[Fallback: GCP Cloud Run (Scale-to-0)<br/>Standby 💰 $0/mo, Auto-Boot ~200ms]
    end

    subgraph 【Tier 3: Database & State Persistence Layer】
        App_Primary -->|Primary Read/Write (Direct)| DB_Primary[(Primary: Local postgresql.svc.plus<br/>Full pgvector / C-Extension Support)]
        App_Fallback -->|Fallback Read/Write (Supavisor 6543)| DB_Fallback[(Fallback: Supabase Cloud PostgreSQL<br/>Managed Cloud DB / Automated Daily Backup)]
        DB_Primary -.->|PG Logical Replication (wal_level=logical) Real-time Sync| DB_Fallback
    end
```

---

## 📊 3. 3-Tier Fallback Specification Matrix

| Layer | Primary Environment (Self-Hosted) | Fallback Environment (Cloud Serverless) | Failover Trigger | Data Consistency & User Experience |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1: Frontend** | **VPS Caddy Static Hosting** (`console.svc.plus`) | **Cloudflare Pages / Vercel** (Global CDN) | Edge gateway detects web port disconnection or TLS errors | Millisecond redirect to CDN mirror; instant load with 0 user friction |
| **Tier 2: Compute** | **Docker Compose / k3s / Sealos Go Containers** | **GCP Cloud Run** (Scale-to-0 Container) | `edge-gateway` encounters 2.5s timeout, network refusal, or `5xx` | **In-flight transparent retry fallback**; response header marked with `X-Upstream-Route: cloud-run-fallback` |
| **Tier 3: Database** | **Self-Hosted `postgresql.svc.plus`** (Full C extensions) | **Supabase Cloud PostgreSQL** (Managed Instance) | Compute failover routes to Cloud Run, which connects to Supabase | Real-time incremental synchronization via PG Logical Replication ensures 0 data loss |

---

## 🛠️ 4. Multi-Mode Self-Hosted Primary Node Deployment

The primary node supports both single-node and multi-node setups with identical disaster-recovery interfaces:

### 1. Single-Node Minimalist Mode (Docker Compose + Caddy)
* **Target Spec**: Single 2 vCPU / 4GB or 4 vCPU / 8GB VPS ($5~$10/mo).
* **Stack**:
  * **Caddy**: Automatic TLS, static asset caching, reverse proxy;
  * **Docker Compose**: Orchestrating `accounts`, `billing-service`, `content-service`;
  * **PostgreSQL**: Local `postgresql.svc.plus` mounted on NVMe storage.
* **Benefits**: Total memory overhead < 1.5GB, easily handling 500~1,500 QPS.

### 2. Multi-Node High-Availability Mode (Sealos / k3s Lightweight Cluster)
* **Target Spec**: 2~3 multi-region VPS nodes (e.g. Tokyo + Singapore + Frankfurt).
* **Stack**:
  * **Sealos** (`sealos run labring/k8s:v1.27.0`) boots an HA Kubernetes cluster in minutes;
  * Microservices deployed with Deployments + HPA, exposed via Sealos Ingress.
* **Benefits**: Automatic Pod failover within the cluster during single VPS hardware issues; global fallback to Cloud Run only on complete network/datacenter disaster.

---

## 🔄 5. Database Layer Incremental Sync & Hot Standby

Data consistency is preserved through **"Local Master, Cloud Hot Standby"** incremental replication:

```mermaid
graph LR
    subgraph Steady-State Workflow (99% of time)
        LocalApp[VPS Go Microservices] -->|Read/Write Local| LocalDB[(Master: VPS postgresql.svc.plus<br/>wal_level = logical)]
        LocalDB -->|PG Logical Replication pgoutput (ms-level)| SupaDB[(Hot Standby: Supabase Cloud PostgreSQL)]
    end

    subgraph Disaster Recovery Workflow (VPS Outage)
        CloudRun[GCP Cloud Run Standby] -->|Active Read/Write (Supavisor 6543)| SupaDB
    end
```

### 1. Enable PostgreSQL Logical Replication (Publisher)
Configure `postgresql.conf` on local `postgresql.svc.plus`:
```ini
wal_level = logical
max_wal_senders = 10
max_replication_slots = 10
```
Create the publication:
```sql
CREATE PUBLICATION pub_ai_workspace FOR ALL TABLES;
```

### 2. Create Subscription on Supabase Cloud (Subscriber)
Execute on Supabase SQL editor:
```sql
CREATE SUBSCRIPTION sub_ai_workspace
  CONNECTION 'host=vps-db.svc.plus port=5443 dbname=postgres user=replicator password=xxx sslmode=require'
  PUBLICATION pub_ai_workspace;
```

### 3. Failover & Split-Brain Prevention
* When primary node fails, `edge-gateway.svc.plus` diverts traffic to GCP Cloud Run;
* Cloud Run connects to Supabase pooler:
  `DATABASE_URL=postgres://postgres.[REF]:[PWD]@aws-0-[REGION].pooler.supabase.com:6543/postgres`
* Business operations resume with sub-second replication lag.

---

## 🚀 6. Edge Gateway (`edge-gateway.svc.plus`) Orchestration

Deployed globally across Cloudflare edges, the gateway orchestrates health checks and failovers:

1. **Deep Health Checks**:
   - Probes `/api/v1/health` on primary VPS, validating both **Go API health + local DB `SELECT 1` connectivity**;
2. **In-Flight Single-Invocation Failover**:
   - Routes to primary VPS with 2.5s circuit breaker;
   - On timeout or `5xx`, immediately retries and serves from GCP Cloud Run in the same client request.

---

## 💰 7. Total Cost of Ownership (TCO) & SLA Projections

| Scenario | Primary State | Cloud Standby State | Total Monthly Cost | Availability (SLA) |
| :--- | :--- | :--- | :--- | :--- |
| **Normal Operations (99%)** | VPS fully operational ($5/mo) | Cloud Run (0 instances $0) + Supabase ($0) + CF ($0) | **~$5.00 / mo** | **99.9%** (0 cold start, fast response) |
| **VPS Outage / Datacenter Down** | Offline / Unreachable | Cloud Run activated + Supabase takes traffic (~$0.50) | **~$5.50 / mo** | **99.99%** (Zero downtime failover) |
| **10x Traffic Spike Surge** | VPS at 100% capacity | Overflow traffic absorbed by Cloud Run | Granular per-second pricing | **Resilient to avalanches** |

---

## 📋 8. Production Hardening Checklist

- [ ] **Logical Replication Config**: Set `wal_level = logical` on local `postgresql.svc.plus` and establish secure TLS subscription from Supabase.
- [ ] **Connection Pooler Protection**: Configure Go services on Cloud Run to connect via Supabase **Supavisor (port 6543)** and set `SetMaxOpenConns(5)`.
- [ ] **Deep Health Probe**: Ensure primary Go microservice `/api/v1/health` verifies database connectivity.
- [ ] **Vault Upstream Secrets**: Inject `PRIMARY_UPSTREAM` and `FALLBACK_UPSTREAM` into `edge-gateway.svc.plus` via `vault.svc.plus`.
- [ ] **Frontend Dual Deployment**: Configure GitHub Actions to push static console artifacts to both VPS Caddy root and Cloudflare Pages.
